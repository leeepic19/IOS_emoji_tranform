"""
情绪识别模型配置文件 - 中文小模型版本
"""

# 17个目标emoji
EMOJI_LIST = ["😂", "😄", "🥹", "😅", "😁", "🤓", "🥲", "😎", "🧐", "😱", "😡", "🫡", "🥰", "😨", "😠", "😑", "😭"]

# emoji到索引的映射
EMOJI_TO_ID = {emoji: idx for idx, emoji in enumerate(EMOJI_LIST)}
ID_TO_EMOJI = {idx: emoji for idx, emoji in enumerate(EMOJI_LIST)}

# 模型配置 - 使用小型中文模型，适合移动端部署
MODEL_CONFIG = {
    # hfl/rbt3: 3层RoBERTa，约38M参数
    # hfl/rbt6: 6层RoBERTa，约60M参数
    # bert-base-chinese: 12层BERT，约102M参数 ✅ 量化后适合iOS
    "model_name": "bert-base-chinese",  # 量化后约100MB，iOS流畅运行
    "max_length": 128,
    "num_labels": len(EMOJI_LIST),  # 17个emoji
}

# 训练配置 - 全参数微调
TRAINING_CONFIG = {
    "batch_size": 16,
    "learning_rate": 5e-5,
    "num_epochs": 30,
    "warmup_ratio": 0.1,
    "weight_decay": 0.01,
    "save_steps": 100,
    "eval_steps": 100,
    "logging_steps": 50,
    "use_class_weights": True,
}

# 路径配置
PATH_CONFIG = {
    "train_file": "./dataset/train.json",
    "val_file": "./dataset/val.json",
    "output_dir": "./output",
    "model_save_path": "./output/emoji_model",
    "onnx_path": "./output/emoji_model.onnx",
}
