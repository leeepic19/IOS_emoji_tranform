# 🎭 iOS Emoji Transform

> 实时语音情绪识别 → Emoji 转换，部署于 iOS 设备

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2015+-blue?logo=apple" />
  <img src="https://img.shields.io/badge/Model-BERT--Chinese-orange?logo=pytorch" />
  <img src="https://img.shields.io/badge/CoreML-INT8%20Quantized-green?logo=apple" />
  <img src="https://img.shields.io/badge/Size-98MB-lightgrey" />
</p>

## 📸 演示效果

<p align="center">
  <img src="emotion_recognition/assets/demo1.jpg" width="45%" />
  <img src="emotion_recognition/assets/demo2.jpg" width="45%" />
</p>

## ✨ 功能特点

- 🎤 **实时语音情绪识别** - 配合 Speech Framework 实现
- ⚡ **低延迟推理** - Neural Engine 加速，<50ms 响应
- 📱 **轻量部署** - INT8 量化模型仅 98MB
- 🎯 **17种情绪** - 覆盖常用表情场景

## 🎭 支持的 Emoji

| 😂 大笑 | 😄 开心 | 🥹 感动 | 😅 尴尬 | 😁 得意 |
|:---:|:---:|:---:|:---:|:---:|
| 🤓 认真 | 🥲 苦笑 | 😎 酷 | 🧐 疑惑 | 😱 惊恐 |
| 😡 愤怒 | 🫡 致敬 | 🥰 喜爱 | 😨 害怕 | 😠 生气 |
| 😑 无语 | 😭 大哭 | | | |

## 📁 项目结构

```
├── EmojiTransformer/          # iOS App 代码
│   └── ...
├── emotion_recognition/       # 模型训练代码
│   ├── train.py              # 训练脚本
│   ├── config.py             # 配置文件
│   ├── dataset/              # 训练数据
│   ├── output/               # 导出模型
│   └── ios_integration/      # Swift 集成代码
└── README.md
```


### 模型训练

```bash
cd emotion_recognition
pip install -r requirements.txt
python train.py
```

## 快速开始
没有上传完整模型，如需测试可以自行根据数据集微调

```bash
python test_realtime.py
```
命令行测试模拟口语环境，只识别10秒缓存区中20个字

## 📊 模型信息

| 项目 | 详情 |
|------|------|
| 基座模型 | bert-base-chinese (102M) |
| 量化方式 | INT8 |
| 模型大小 | 98 MB |
| 验证准确率 | 46.6% |（部分emoji相似度高，大类准确率完全够）
| 训练数据 | 546 条中文情绪文本 |



<p align="center">Made with ❤️ for iOS</p>
