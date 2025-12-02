"""
将 ONNX 模型转换为 CoreML 格式
此脚本需要在 Mac 上运行（因为 coremltools 主要支持 macOS）
"""

import os
import numpy as np


def convert_onnx_to_coreml(onnx_path, output_path="emotion_model.mlmodel"):
    """将 ONNX 模型转换为 CoreML 格式"""
    
    try:
        import coremltools as ct
        from coremltools.models.neural_network import quantization_utils
    except ImportError:
        print("Error: coremltools not installed.")
        print("Install it with: pip install coremltools")
        return None
    
    print("="*60)
    print("Converting ONNX to CoreML")
    print("="*60)
    
    print(f"\nLoading ONNX model from: {onnx_path}")
    
    # 转换 ONNX 到 CoreML
    # 使用 float16 来减小模型大小
    model = ct.converters.onnx.convert(
        model=onnx_path,
        minimum_ios_deployment_target='15.0'  # iOS 15+
    )
    
    # 添加元数据
    model.author = "Emotion Recognition Model"
    model.short_description = "Recognizes emotions from text and returns emoji"
    model.version = "1.0"
    
    # 添加输入输出描述
    model.input_description['input_ids'] = "Tokenized input text (int32)"
    model.input_description['attention_mask'] = "Attention mask (int32)"
    model.output_description['logits'] = "Emotion class logits"
    
    # 保存模型
    model.save(output_path)
    
    print(f"\n✓ CoreML model saved to: {output_path}")
    print(f"  File size: {os.path.getsize(output_path) / 1e6:.2f} MB")
    
    return output_path


def convert_with_ct_convert(onnx_path, output_path="emotion_model.mlmodel"):
    """使用新版 coremltools API 转换"""
    
    try:
        import coremltools as ct
    except ImportError:
        print("Error: coremltools not installed.")
        print("Install it with: pip install coremltools")
        return None
    
    print("="*60)
    print("Converting ONNX to CoreML (using ct.convert)")
    print("="*60)
    
    print(f"\nLoading ONNX model from: {onnx_path}")
    
    # 使用新版 API 转换
    model = ct.convert(
        onnx_path,
        source='onnx',
        convert_to='mlprogram',  # 使用 ML Program 格式（iOS 15+）
        minimum_deployment_target=ct.target.iOS15,
        compute_precision=ct.precision.FLOAT16,  # 使用 FP16 减小模型
    )
    
    # 添加元数据
    model.author = "Emotion Recognition"
    model.short_description = "Converts text to emotion emoji"
    model.version = "1.0"
    
    # 定义输出路径
    mlpackage_path = output_path.replace('.mlmodel', '.mlpackage')
    
    # 保存模型
    model.save(mlpackage_path)
    
    print(f"\n✓ CoreML model saved to: {mlpackage_path}")
    
    # 获取文件夹大小
    total_size = 0
    for dirpath, dirnames, filenames in os.walk(mlpackage_path):
        for f in filenames:
            fp = os.path.join(dirpath, f)
            total_size += os.path.getsize(fp)
    
    print(f"  Package size: {total_size / 1e6:.2f} MB")
    
    return mlpackage_path


def create_emotion_classifier():
    """显示emoji映射"""
    
    # 17个目标emoji
    emoji_list = ["😂", "�", "🥹", "😅", "�", "🤓", "🥲", "😎", "🧐", "😱", "�", "🫡", "🥰", "😨", "😠", "�", "😭"]
    
    print("\nEmoji mapping (17 classes):")
    for idx, emoji in enumerate(emoji_list):
        print(f"  {idx}: {emoji}")
    
    return emoji_list


if __name__ == "__main__":
    import sys
    
    # 默认 ONNX 路径
    onnx_path = "./output/emoji_model.onnx"
    
    if len(sys.argv) > 1:
        onnx_path = sys.argv[1]
    
    if not os.path.exists(onnx_path):
        print(f"Error: ONNX file not found: {onnx_path}")
        print("Please run export_onnx.py first, or provide the correct path.")
        sys.exit(1)
    
    # 显示emoji映射
    create_emotion_classifier()
    
    # 尝试使用新版 API 转换
    try:
        output_path = convert_with_ct_convert(onnx_path)
    except Exception as e:
        print(f"New API failed: {e}")
        print("\nTrying legacy API...")
        output_path = convert_onnx_to_coreml(onnx_path)
    
    if output_path:
        print("\n" + "="*60)
        print("Conversion complete!")
        print("="*60)
        print(f"\nYou can now use the model in your iOS app.")
        print("Import the .mlmodel or .mlpackage file into your Xcode project.")
        print("\nIn iOS, use sigmoid on logits and take argmax to get the emoji index.")
