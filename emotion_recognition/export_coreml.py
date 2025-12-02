"""
完整的模型导出流程：PyTorch → ONNX → CoreML (量化)
适用于 iOS 部署
"""

import os
import json
import torch
import numpy as np
from transformers import AutoModelForSequenceClassification, AutoTokenizer
from config import MODEL_CONFIG, PATH_CONFIG, EMOJI_LIST, ID_TO_EMOJI


def export_to_onnx():
    """Step 1: 导出模型为 ONNX 格式"""
    
    print("="*60)
    print("Step 1: Exporting model to ONNX format")
    print("="*60)
    
    model_path = PATH_CONFIG['model_save_path']
    print(f"\nLoading model from: {model_path}")
    
    model = AutoModelForSequenceClassification.from_pretrained(model_path)
    tokenizer = AutoTokenizer.from_pretrained(model_path)
    model.eval()
    
    # 创建示例输入
    dummy_text = "今天真的太开心了"
    inputs = tokenizer(
        dummy_text,
        padding='max_length',
        truncation=True,
        max_length=MODEL_CONFIG['max_length'],
        return_tensors='pt'
    )
    
    onnx_path = PATH_CONFIG['onnx_path']
    os.makedirs(os.path.dirname(onnx_path), exist_ok=True)
    
    print(f"Exporting to: {onnx_path}")
    
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
    
    file_size = os.path.getsize(onnx_path) / 1e6
    print(f"✓ ONNX model exported! Size: {file_size:.2f} MB")
    
    return onnx_path, tokenizer


def convert_to_coreml(onnx_path, quantize=True):
    """Step 2: 转换为 CoreML 格式并量化"""
    
    try:
        import coremltools as ct
    except ImportError:
        print("Error: coremltools not installed.")
        print("Install with: pip install coremltools")
        return None
    
    print("\n" + "="*60)
    print("Step 2: Converting to CoreML format")
    print("="*60)
    
    print(f"\nLoading ONNX model: {onnx_path}")
    
    # 转换为 CoreML ML Program 格式 (iOS 15+)
    model = ct.convert(
        onnx_path,
        source='onnx',
        convert_to='mlprogram',
        minimum_deployment_target=ct.target.iOS15,
        compute_precision=ct.precision.FLOAT16,  # FP16 精度
    )
    
    # 添加元数据
    model.author = "Emotion Recognition"
    model.short_description = "中文文本情绪识别 → Emoji"
    model.version = "1.0"
    
    # FP16 模型路径
    fp16_path = "./output/emoji_model_fp16.mlpackage"
    model.save(fp16_path)
    
    fp16_size = get_folder_size(fp16_path) / 1e6
    print(f"✓ FP16 model saved: {fp16_path}")
    print(f"  Size: {fp16_size:.2f} MB")
    
    if quantize:
        print("\n" + "="*60)
        print("Step 3: Quantizing to INT8")
        print("="*60)
        
        try:
            # 使用 INT8 量化进一步压缩
            from coremltools.models.neural_network import quantization_utils
            
            # 对于 mlprogram，使用 ct.compression
            try:
                # 新版 coremltools 6.0+ 的量化方式
                op_config = ct.optimize.coreml.OpLinearQuantizerConfig(
                    mode="linear_symmetric",
                    weight_threshold=512,
                )
                config = ct.optimize.coreml.OptimizationConfig(global_config=op_config)
                quantized_model = ct.optimize.coreml.linear_quantize_weights(model, config=config)
                
                int8_path = "./output/emoji_model_int8.mlpackage"
                quantized_model.save(int8_path)
                
                int8_size = get_folder_size(int8_path) / 1e6
                print(f"✓ INT8 model saved: {int8_path}")
                print(f"  Size: {int8_size:.2f} MB")
                print(f"  Compression ratio: {fp16_size/int8_size:.1f}x")
                
                return int8_path
            except Exception as e:
                print(f"INT8 quantization failed: {e}")
                print("Using FP16 model instead.")
                return fp16_path
                
        except Exception as e:
            print(f"Quantization error: {e}")
            return fp16_path
    
    return fp16_path


def get_folder_size(path):
    """获取文件夹大小"""
    total_size = 0
    if os.path.isfile(path):
        return os.path.getsize(path)
    for dirpath, dirnames, filenames in os.walk(path):
        for f in filenames:
            fp = os.path.join(dirpath, f)
            total_size += os.path.getsize(fp)
    return total_size


def save_tokenizer_config(tokenizer, output_dir="./output"):
    """保存 tokenizer 配置供 iOS 使用"""
    
    print("\n" + "="*60)
    print("Saving tokenizer config for iOS")
    print("="*60)
    
    # 保存 vocab
    vocab_path = os.path.join(output_dir, "vocab.txt")
    if hasattr(tokenizer, 'vocab'):
        with open(vocab_path, 'w', encoding='utf-8') as f:
            for token in sorted(tokenizer.vocab.keys(), key=lambda x: tokenizer.vocab[x]):
                f.write(token + '\n')
        print(f"✓ Vocab saved: {vocab_path}")
    
    # 保存 emoji 映射
    emoji_map = {str(i): emoji for i, emoji in enumerate(EMOJI_LIST)}
    emoji_path = os.path.join(output_dir, "emoji_map.json")
    with open(emoji_path, 'w', encoding='utf-8') as f:
        json.dump(emoji_map, f, ensure_ascii=False, indent=2)
    print(f"✓ Emoji map saved: {emoji_path}")
    
    # 保存模型配置
    config = {
        "model_name": MODEL_CONFIG['model_name'],
        "max_length": MODEL_CONFIG['max_length'],
        "num_labels": MODEL_CONFIG['num_labels'],
        "emoji_list": EMOJI_LIST,
    }
    config_path = os.path.join(output_dir, "model_config.json")
    with open(config_path, 'w', encoding='utf-8') as f:
        json.dump(config, f, ensure_ascii=False, indent=2)
    print(f"✓ Config saved: {config_path}")


def test_onnx_model(onnx_path):
    """测试 ONNX 模型"""
    
    try:
        import onnxruntime as ort
    except ImportError:
        print("onnxruntime not installed, skipping ONNX test")
        return
    
    print("\n" + "="*60)
    print("Testing ONNX model")
    print("="*60)
    
    tokenizer = AutoTokenizer.from_pretrained(PATH_CONFIG['model_save_path'])
    session = ort.InferenceSession(onnx_path)
    
    test_texts = [
        "哈哈哈笑死我了",
        "今天好开心啊",
        "气死我了这人",
        "呜呜呜好难过",
        "有点紧张",
    ]
    
    print("\nTest predictions:")
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
        
        logits = outputs[0][0]
        pred_id = np.argmax(logits)
        pred_emoji = ID_TO_EMOJI[pred_id]
        
        print(f"  {text} → {pred_emoji}")


def main():
    """主函数"""
    
    print("\n" + "="*60)
    print("🚀 Emotion Model Export Pipeline for iOS")
    print("="*60)
    print(f"\nModel: {MODEL_CONFIG['model_name']}")
    print(f"Labels: {len(EMOJI_LIST)} emojis")
    print(f"Emojis: {''.join(EMOJI_LIST)}")
    
    # Step 1: 导出 ONNX
    onnx_path, tokenizer = export_to_onnx()
    
    # 测试 ONNX
    test_onnx_model(onnx_path)
    
    # Step 2: 转换为 CoreML（量化）
    coreml_path = convert_to_coreml(onnx_path, quantize=True)
    
    # 保存 tokenizer 配置
    save_tokenizer_config(tokenizer)
    
    # 总结
    print("\n" + "="*60)
    print("✅ Export Complete!")
    print("="*60)
    print("\nOutput files:")
    print(f"  ONNX:    {onnx_path}")
    if coreml_path:
        print(f"  CoreML:  {coreml_path}")
    print(f"  Config:  ./output/model_config.json")
    print(f"  Vocab:   ./output/vocab.txt")
    print(f"  Emoji:   ./output/emoji_map.json")
    print("\n📱 iOS Integration:")
    print("  1. 将 .mlpackage 拖入 Xcode 项目")
    print("  2. 使用 BertTokenizer 对输入文本进行分词")
    print("  3. 调用模型获取 logits，取 argmax 得到 emoji index")
    print("  4. 根据 emoji_map.json 映射到对应 emoji")


if __name__ == "__main__":
    main()
