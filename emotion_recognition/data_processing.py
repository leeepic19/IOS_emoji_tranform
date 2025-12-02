"""
数据处理脚本 - 中文单标签版本（改进版）
加载自定义JSON格式的中文情绪数据集
"""

import json
import torch
import numpy as np
from collections import Counter
from transformers import AutoTokenizer
from torch.utils.data import DataLoader, Dataset
from config import MODEL_CONFIG, TRAINING_CONFIG, EMOJI_TO_ID, EMOJI_LIST, PATH_CONFIG


class EmojiDataset(Dataset):
    """中文emoji单标签数据集类"""
    
    def __init__(self, encodings, labels):
        self.encodings = encodings
        self.labels = labels
    
    def __len__(self):
        return len(self.labels)
    
    def __getitem__(self, idx):
        item = {key: torch.tensor(val[idx]) for key, val in self.encodings.items()}
        # 单标签分类：使用long tensor
        item['labels'] = torch.tensor(self.labels[idx], dtype=torch.long)
        return item


def load_json_data(file_path):
    """加载JSON数据文件"""
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return data


def convert_to_single_label(emojis_list):
    """将emoji列表转换为单标签索引（只取第一个emoji）"""
    if emojis_list and emojis_list[0] in EMOJI_TO_ID:
        return EMOJI_TO_ID[emojis_list[0]]
    return 0


def convert_data_to_single_label(data):
    """
    将数据转换为单标签格式（只取每条数据的第一个emoji）
    例如：{"text": "xxx", "emojis": ["😂", "😄"]} 
    转换为：{"text": "xxx", "label": 0}  (只保留第一个emoji 😂)
    """
    converted = []
    for item in data:
        text = item['text']
        emojis = item['emojis']
        if emojis and emojis[0] in EMOJI_TO_ID:
            converted.append({
                'text': text,
                'label': EMOJI_TO_ID[emojis[0]]
            })
    return converted


def compute_class_weights(labels):
    """计算类别权重来处理不平衡问题"""
    label_counts = Counter(labels)
    total = len(labels)
    num_classes = len(EMOJI_LIST)
    
    weights = []
    for i in range(num_classes):
        count = label_counts.get(i, 1)  # 避免除零
        # 使用 inverse frequency
        weight = total / (num_classes * count)
        weights.append(weight)
    
    # 归一化
    weights = np.array(weights)
    weights = weights / weights.sum() * num_classes
    
    return torch.tensor(weights, dtype=torch.float)


def load_and_process_data():
    """加载并处理自定义中文数据集 - 单标签版本（只取第一个emoji）"""
    import sys
    
    print("Loading custom Chinese emoji dataset (single-label mode - first emoji only)...")
    sys.stdout.flush()
    
    # 加载训练和验证数据
    print(f"[DEBUG] Loading train file: {PATH_CONFIG['train_file']}")
    sys.stdout.flush()
    train_data_raw = load_json_data(PATH_CONFIG['train_file'])
    print(f"[DEBUG] Loading val file: {PATH_CONFIG['val_file']}")
    sys.stdout.flush()
    val_data_raw = load_json_data(PATH_CONFIG['val_file'])
    
    # 转换为单标签（只取第一个emoji）
    print("[DEBUG] Converting to single-label (using first emoji only)...")
    sys.stdout.flush()
    train_data = convert_data_to_single_label(train_data_raw)
    val_data = convert_data_to_single_label(val_data_raw)
    
    print(f"Dataset converted (first emoji only):")
    print(f"  Train samples: {len(train_data_raw)} -> {len(train_data)}")
    print(f"  Validation samples: {len(val_data_raw)} -> {len(val_data)}")
    sys.stdout.flush()
    
    # 提取文本和标签
    train_texts = [item['text'] for item in train_data]
    train_labels = [item['label'] for item in train_data]
    val_texts = [item['text'] for item in val_data]
    val_labels = [item['label'] for item in val_data]
    
    # 计算类别权重
    print("[DEBUG] Computing class weights...")
    sys.stdout.flush()
    class_weights = compute_class_weights(train_labels)
    print(f"Class weights: {class_weights}")
    sys.stdout.flush()
    
    # 加载tokenizer
    print(f"\nLoading tokenizer: {MODEL_CONFIG['model_name']}")
    print("[DEBUG] This may take a while if downloading for the first time...")
    sys.stdout.flush()
    tokenizer = AutoTokenizer.from_pretrained(MODEL_CONFIG['model_name'])
    print("[DEBUG] Tokenizer loaded")
    sys.stdout.flush()
    
    # 分词
    def tokenize_texts(texts):
        return tokenizer(
            texts,
            padding='max_length',
            truncation=True,
            max_length=MODEL_CONFIG['max_length'],
            return_tensors=None
        )
    
    print("\nTokenizing datasets...")
    sys.stdout.flush()
    tokenized_train = tokenize_texts(train_texts)
    tokenized_val = tokenize_texts(val_texts)
    
    # 创建 PyTorch Dataset
    train_dataset = EmojiDataset(tokenized_train, train_labels)
    val_dataset = EmojiDataset(tokenized_val, val_labels)
    
    print(f"\nDatasets created:")
    print(f"  Train: {len(train_dataset)} samples")
    print(f"  Validation: {len(val_dataset)} samples")
    sys.stdout.flush()
    
    # 统计emoji分布
    print("\nEmoji distribution in training set:")
    label_counts = Counter(train_labels)
    for i in range(len(EMOJI_LIST)):
        count = label_counts.get(i, 0)
        print(f"  {EMOJI_LIST[i]}: {count}")
    sys.stdout.flush()
    
    return train_dataset, val_dataset, class_weights, tokenizer


def create_dataloaders(train_dataset, val_dataset):
    """创建数据加载器"""
    
    batch_size = TRAINING_CONFIG['batch_size']
    
    train_loader = DataLoader(
        train_dataset, 
        batch_size=batch_size, 
        shuffle=True,
        num_workers=0,  # 避免tokenizer警告
        pin_memory=True
    )
    
    val_loader = DataLoader(
        val_dataset, 
        batch_size=batch_size, 
        shuffle=False,
        num_workers=0,
        pin_memory=True
    )
    
    return train_loader, val_loader


if __name__ == "__main__":
    # 测试数据加载
    train_dataset, val_dataset, class_weights, tokenizer = load_and_process_data()
    train_loader, val_loader = create_dataloaders(train_dataset, val_dataset)
    
    # 查看一个batch
    batch = next(iter(train_loader))
    print(f"\nBatch shapes:")
    for key, val in batch.items():
        print(f"  {key}: {val.shape}")
    
    print(f"\nFirst sample label: {batch['labels'][0]} -> {EMOJI_LIST[batch['labels'][0]]}")
