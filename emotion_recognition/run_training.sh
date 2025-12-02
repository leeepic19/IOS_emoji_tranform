#!/bin/bash
# 情绪识别模型训练和导出脚本
# 在 Ubuntu 4090 服务器上运行

set -e  # 遇到错误立即退出

echo "=============================================="
echo "Emotion Recognition Model Training Pipeline"
echo "=============================================="

# 检查 CUDA
echo ""
echo "Checking CUDA availability..."
python3 -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}'); print(f'GPU: {torch.cuda.get_device_name(0)}' if torch.cuda.is_available() else '')"

# 步骤 1: 训练模型
echo ""
echo "=============================================="
echo "Step 1: Training the model..."
echo "=============================================="
python3 train.py

# 步骤 2: 导出为 ONNX
echo ""
echo "=============================================="
echo "Step 2: Exporting to ONNX..."
echo "=============================================="
python3 export_onnx.py

echo ""
echo "=============================================="
echo "Training pipeline complete!"
echo "=============================================="
echo ""
echo "Next steps:"
echo "1. Download the ONNX model: output/emotion_model.onnx"
echo "2. Download the tokenizer: output/emotion_model/"
echo "3. Run convert_to_coreml.py on your Mac to convert to CoreML"
echo ""
echo "Files to download:"
ls -lh output/
