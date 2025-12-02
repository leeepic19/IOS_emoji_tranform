"""
中文Emoji情绪识别模型训练脚本 - 全参数微调版本
使用中文BERT进行文本分类
"""

import os
import torch
import torch.nn as nn
from torch.optim import AdamW
from transformers import (
    AutoModelForSequenceClassification,
    AutoTokenizer,
    get_linear_schedule_with_warmup
)
from sklearn.metrics import accuracy_score, f1_score, classification_report
from tqdm import tqdm
import numpy as np

from config import MODEL_CONFIG, TRAINING_CONFIG, PATH_CONFIG, EMOJI_LIST, ID_TO_EMOJI
from data_processing import load_and_process_data, create_dataloaders


def setup_device():
    """设置训练设备"""
    if torch.cuda.is_available():
        device = torch.device("cuda")
        print(f"Using GPU: {torch.cuda.get_device_name(0)}")
        print(f"GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.2f} GB")
    else:
        device = torch.device("cpu")
        print("Using CPU")
    return device


def load_model():
    """加载预训练模型 - 全参数微调"""
    print(f"\nLoading model: {MODEL_CONFIG['model_name']}")
    
    # 加载模型
    model = AutoModelForSequenceClassification.from_pretrained(
        MODEL_CONFIG['model_name'],
        num_labels=MODEL_CONFIG['num_labels'],
    )
    
    # 统计参数
    total_params = sum(p.numel() for p in model.parameters())
    trainable_params = sum(p.numel() for p in model.parameters() if p.requires_grad)
    
    print(f"Total parameters: {total_params:,}")
    print(f"Trainable parameters: {trainable_params:,}")
    print(f"Number of labels: {MODEL_CONFIG['num_labels']}")
    
    return model


def train_epoch(model, train_loader, optimizer, scheduler, device, criterion=None):
    """训练一个epoch"""
    model.train()
    total_loss = 0
    all_preds = []
    all_labels = []
    
    progress_bar = tqdm(train_loader, desc="Training")
    
    for batch in progress_bar:
        # 移动数据到设备
        input_ids = batch['input_ids'].to(device)
        attention_mask = batch['attention_mask'].to(device)
        labels = batch['labels'].to(device)
        
        # 前向传播
        optimizer.zero_grad()
        outputs = model(
            input_ids=input_ids,
            attention_mask=attention_mask,
        )
        
        logits = outputs.logits
        
        # 使用加权损失或普通交叉熵
        if criterion is not None:
            loss = criterion(logits, labels)
        else:
            loss = nn.CrossEntropyLoss()(logits, labels)
        
        # 反向传播
        loss.backward()
        torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
        optimizer.step()
        scheduler.step()
        
        # 记录
        total_loss += loss.item()
        preds = torch.argmax(logits, dim=1)
        all_preds.extend(preds.cpu().numpy())
        all_labels.extend(labels.cpu().numpy())
        
        progress_bar.set_postfix({'loss': f'{loss.item():.4f}'})
    
    avg_loss = total_loss / len(train_loader)
    accuracy = accuracy_score(all_labels, all_preds)
    
    return avg_loss, accuracy


def evaluate(model, data_loader, device, desc="Evaluating"):
    """评估模型"""
    model.eval()
    total_loss = 0
    all_preds = []
    all_labels = []
    all_probs = []
    
    criterion = nn.CrossEntropyLoss()
    
    with torch.no_grad():
        progress_bar = tqdm(data_loader, desc=desc)
        
        for batch in progress_bar:
            input_ids = batch['input_ids'].to(device)
            attention_mask = batch['attention_mask'].to(device)
            labels = batch['labels'].to(device)
            
            outputs = model(
                input_ids=input_ids,
                attention_mask=attention_mask,
            )
            
            logits = outputs.logits
            loss = criterion(logits, labels)
            
            total_loss += loss.item()
            
            probs = torch.softmax(logits, dim=1)
            preds = torch.argmax(probs, dim=1)
            
            all_preds.extend(preds.cpu().numpy())
            all_labels.extend(labels.cpu().numpy())
            all_probs.extend(probs.cpu().numpy())
    
    avg_loss = total_loss / len(data_loader)
    accuracy = accuracy_score(all_labels, all_preds)
    f1 = f1_score(all_labels, all_preds, average='weighted')
    
    return avg_loss, accuracy, f1, all_preds, all_labels, all_probs


def train(model, train_loader, val_loader, device, class_weights=None):
    """完整训练流程"""
    
    # 设置优化器
    optimizer = AdamW(
        model.parameters(),
        lr=TRAINING_CONFIG['learning_rate'],
        weight_decay=TRAINING_CONFIG['weight_decay']
    )
    
    # 设置学习率调度器
    total_steps = len(train_loader) * TRAINING_CONFIG['num_epochs']
    warmup_steps = int(total_steps * TRAINING_CONFIG['warmup_ratio'])
    
    scheduler = get_linear_schedule_with_warmup(
        optimizer,
        num_warmup_steps=warmup_steps,
        num_training_steps=total_steps
    )
    
    # 设置损失函数（带类别权重）
    criterion = None
    if class_weights is not None and TRAINING_CONFIG.get('use_class_weights', False):
        criterion = nn.CrossEntropyLoss(weight=class_weights.to(device))
        print("Using weighted cross-entropy loss")
    
    model.to(device)
    best_val_accuracy = 0
    best_val_f1 = 0
    patience = 5  # 早停patience
    no_improve_count = 0
    
    print(f"\n{'='*60}")
    print("Starting training...")
    print(f"Total steps: {total_steps}, Warmup steps: {warmup_steps}")
    print(f"{'='*60}")
    
    for epoch in range(TRAINING_CONFIG['num_epochs']):
        print(f"\n--- Epoch {epoch + 1}/{TRAINING_CONFIG['num_epochs']} ---")
        
        # 训练
        train_loss, train_acc = train_epoch(
            model, train_loader, optimizer, scheduler, device, criterion
        )
        print(f"Train Loss: {train_loss:.4f}, Train Accuracy: {train_acc:.4f}")
        
        # 验证
        val_loss, val_acc, val_f1, _, _, _ = evaluate(model, val_loader, device, "Validating")
        print(f"Val Loss: {val_loss:.4f}, Val Accuracy: {val_acc:.4f}, Val F1: {val_f1:.4f}")
        
        # 保存最佳模型（基于F1分数）
        if val_f1 > best_val_f1:
            best_val_f1 = val_f1
            best_val_accuracy = val_acc
            save_model(model, PATH_CONFIG['model_save_path'])
            print(f"✓ New best model saved! F1: {val_f1:.4f}, Acc: {val_acc:.4f}")
            no_improve_count = 0
        else:
            no_improve_count += 1
            print(f"No improvement for {no_improve_count} epochs")
        
        # 早停
        if no_improve_count >= patience:
            print(f"\nEarly stopping at epoch {epoch + 1}")
            break
    
    print(f"\nBest validation accuracy: {best_val_accuracy:.4f}")
    print(f"Best validation F1: {best_val_f1:.4f}")
    
    return model


def save_model(model, save_path):
    """保存模型"""
    os.makedirs(save_path, exist_ok=True)
    model.save_pretrained(save_path)
    
    # 同时保存tokenizer
    tokenizer = AutoTokenizer.from_pretrained(MODEL_CONFIG['model_name'])
    tokenizer.save_pretrained(save_path)
    
    print(f"Model saved to {save_path}")


def show_predictions(model, val_loader, device, tokenizer, num_samples=10):
    """展示一些预测结果"""
    model.eval()
    
    print(f"\n{'='*60}")
    print("Sample Predictions:")
    print(f"{'='*60}")
    
    with torch.no_grad():
        batch = next(iter(val_loader))
        input_ids = batch['input_ids'].to(device)
        attention_mask = batch['attention_mask'].to(device)
        labels = batch['labels'].to(device)
        
        outputs = model(input_ids=input_ids, attention_mask=attention_mask)
        probs = torch.softmax(outputs.logits, dim=1)
        preds = torch.argmax(probs, dim=1)
        
        for i in range(min(num_samples, len(preds))):
            pred_emoji = ID_TO_EMOJI[preds[i].item()]
            true_emoji = ID_TO_EMOJI[labels[i].item()]
            
            # 获取top-3预测
            top3_probs, top3_indices = torch.topk(probs[i], 3)
            top3_emojis = [(ID_TO_EMOJI[idx.item()], f"{prob.item():.2f}") 
                         for idx, prob in zip(top3_indices, top3_probs)]
            
            correct = "✓" if pred_emoji == true_emoji else "✗"
            print(f"{correct} True: {true_emoji} | Pred: {pred_emoji} | Top-3: {top3_emojis}")


def main():
    """主函数"""
    print("="*60)
    print("Chinese Emoji Recognition Model Training (Single-Label)")
    print("="*60)
    import sys
    sys.stdout.flush()
    
    # 创建输出目录
    os.makedirs(PATH_CONFIG['output_dir'], exist_ok=True)
    print("[DEBUG] Output directory created")
    sys.stdout.flush()
    
    # 设置设备
    device = setup_device()
    print(f"[DEBUG] Device setup complete: {device}")
    sys.stdout.flush()
    
    # 加载数据
    print("[DEBUG] Starting to load data...")
    sys.stdout.flush()
    train_dataset, val_dataset, class_weights, tokenizer = load_and_process_data()
    print(f"[DEBUG] Data loaded: train={len(train_dataset)}, val={len(val_dataset)}")
    sys.stdout.flush()
    
    train_loader, val_loader = create_dataloaders(train_dataset, val_dataset)
    print(f"[DEBUG] DataLoaders created")
    sys.stdout.flush()
    
    # 加载模型
    print("[DEBUG] Starting to load model...")
    sys.stdout.flush()
    model = load_model()
    print("[DEBUG] Model loaded successfully")
    sys.stdout.flush()
    
    # 训练
    model = train(model, train_loader, val_loader, device, class_weights)
    
    # 加载最佳模型进行最终评估
    print(f"\n{'='*60}")
    print("Loading best model for final evaluation...")
    print(f"{'='*60}")
    
    model = AutoModelForSequenceClassification.from_pretrained(
        PATH_CONFIG['model_save_path']
    )
    model.to(device)
    
    # 最终评估
    val_loss, val_acc, val_f1, val_preds, val_labels, val_probs = evaluate(
        model, val_loader, device, "Final Evaluation"
    )
    
    print(f"\n{'='*60}")
    print("Final Results")
    print(f"{'='*60}")
    print(f"Validation Loss: {val_loss:.4f}")
    print(f"Validation Accuracy: {val_acc:.4f}")
    print(f"Validation F1 (weighted): {val_f1:.4f}")
    
    # 打印分类报告
    print(f"\n{'='*60}")
    print("Classification Report:")
    print(f"{'='*60}")
    # 只打印有数据的类别
    present_labels = sorted(set(val_labels))
    target_names = [ID_TO_EMOJI[i] for i in present_labels]
    print(classification_report(val_labels, val_preds, labels=present_labels, target_names=target_names))
    
    # 展示一些预测结果
    show_predictions(model, val_loader, device, tokenizer, num_samples=15)
    
    # 统计每个emoji的预测准确率
    print(f"\n{'='*60}")
    print("Per-Emoji Accuracy:")
    print(f"{'='*60}")
    
    emoji_correct = {i: 0 for i in range(len(EMOJI_LIST))}
    emoji_total = {i: 0 for i in range(len(EMOJI_LIST))}
    
    for pred, label in zip(val_preds, val_labels):
        emoji_total[label] += 1
        if pred == label:
            emoji_correct[label] += 1
    
    for i in range(len(EMOJI_LIST)):
        if emoji_total[i] > 0:
            acc = emoji_correct[i] / emoji_total[i]
            print(f"{ID_TO_EMOJI[i]}: {emoji_correct[i]}/{emoji_total[i]} = {acc:.2f}")
    
    print(f"\n✓ Training complete!")
    print(f"Model saved to: {PATH_CONFIG['model_save_path']}")


if __name__ == "__main__":
    main()
