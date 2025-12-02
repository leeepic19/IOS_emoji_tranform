"""
将训练好的模型导出为 ONNX 格式
ONNX 格式可以在后续转换为 CoreML
"""

import os
import torch
import numpy as np
from transformers import AutoModelForSequenceClassification, AutoTokenizer
from config import MODEL_CONFIG, PATH_CONFIG, EMOJI_LIST, ID_TO_EMOJI


def export_to_onnx():
    """导出模型为 ONNX 格式"""
    
    print("="*60)
    print("Exporting model to ONNX format")
    print("="*60)
    
    # 加载训练好的模型
    model_path = PATH_CONFIG['model_save_path']
    print(f"\nLoading model from: {model_path}")
    
    model = AutoModelForSequenceClassification.from_pretrained(model_path)
    tokenizer = AutoTokenizer.from_pretrained(model_path)
    
    model.eval()
    
    # 创建示例输入（中文）
    dummy_text = "今天真的太开心了"
    inputs = tokenizer(
        dummy_text,
        padding='max_length',
        truncation=True,
        max_length=MODEL_CONFIG['max_length'],
        return_tensors='pt'
    )
    
    # ONNX 导出路径
    onnx_path = PATH_CONFIG['onnx_path']
    os.makedirs(os.path.dirname(onnx_path), exist_ok=True)
    
    print(f"\nExporting to: {onnx_path}")
    
    # 导出为 ONNX
    with torch.no_grad():
        torch.onnx.export(
            model,
            (inputs['input_ids'], inputs['attention_mask']),
            onnx_path,
            export_params=True,
            opset_version=14,
            do_constant_folding=True,
            input_names=['input_ids', 'attention_mask'],
            output_names=['logits'],
            dynamic_axes={
                'input_ids': {0: 'batch_size'},
                'attention_mask': {0: 'batch_size'},
                'logits': {0: 'batch_size'}
            }
        )
    
    print(f"✓ ONNX model exported successfully!")
    print(f"  File size: {os.path.getsize(onnx_path) / 1e6:.2f} MB")
    
    # 验证 ONNX 模型
    verify_onnx(onnx_path)
    
    return onnx_path


def verify_onnx(onnx_path):
    """验证 ONNX 模型"""
    import onnx
    import onnxruntime as ort
    
    print("\nVerifying ONNX model...")
    
    # 加载并检查模型
    onnx_model = onnx.load(onnx_path)
    onnx.checker.check_model(onnx_model)
    print("✓ ONNX model structure verified!")
    
    # 使用 ONNX Runtime 进行推理测试
    tokenizer = AutoTokenizer.from_pretrained(PATH_CONFIG['model_save_path'])
    
    session = ort.InferenceSession(onnx_path)
    
    # 中文测试文本
    test_texts = [
        "今天真的太开心了！",
        "卧槽这也太牛逼了吧",
        "好累啊不想起床",
        "气死我了这破游戏",
        "有点紧张明天要考试",
        "呜呜呜好难过啊",
        "哈哈哈笑死我了",
        "我好喜欢你啊",
    ]
    
    print("\nTest inference:")
    for text in test_texts:
        inputs = tokenizer(
            text,
            padding='max_length',
            truncation=True,
            max_length=MODEL_CONFIG['max_length'],
            return_tensors='np'
        )
        
        outputs = session.run(
            None,
            {
                'input_ids': inputs['input_ids'].astype(np.int64),
                'attention_mask': inputs['attention_mask'].astype(np.int64)
            }
        )
        
        logits = outputs[0]
        # 使用sigmoid获取概率
        probs = 1 / (1 + np.exp(-logits))
        pred_class = np.argmax(probs, axis=1)[0]
        confidence = probs[0][pred_class]
        
        emoji = ID_TO_EMOJI[pred_class]
        
        print(f"  '{text}' -> {emoji} ({confidence:.2f})")
    
    print("\n✓ ONNX model inference verified!")


if __name__ == "__main__":
    export_to_onnx()
