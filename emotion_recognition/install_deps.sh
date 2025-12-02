#!/bin/bash
# 安装依赖脚本

echo "Installing dependencies..."

# 升级 pip
pip install --upgrade pip

# 安装 PyTorch (CUDA 11.8 版本，适合 4090)
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# 安装其他依赖
pip install -r requirements.txt

echo ""
echo "Dependencies installed successfully!"
echo ""

# 验证安装
python3 -c "
import torch
print(f'PyTorch version: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'CUDA version: {torch.version.cuda}')
    print(f'GPU: {torch.cuda.get_device_name(0)}')
"
