"""查看数据集样本"""
from datasets import load_dataset

# 加载数据集
print("Loading dataset...")
dataset = load_dataset("dair-ai/emotion")

train_data = dataset["train"]
val_data = dataset["validation"]
test_data = dataset["test"]

print("=== 数据集信息 ===")
print(f"训练集: {len(train_data)} 条")
print(f"验证集: {len(val_data)} 条")
print(f"测试集: {len(test_data)} 条")

print()
print("=== 数据字段 ===")
print(train_data.features)

print()
print("=== 标签映射 ===")
labels = {0: "sadness 😢", 1: "joy 😊", 2: "love ❤️", 3: "anger 😠", 4: "fear 😨", 5: "surprise 😮"}
for k, v in labels.items():
    print(f"  {k}: {v}")

print()
print("=== 每个类别的样本示例 ===")
for label_id in range(6):
    label_name = labels[label_id]
    print(f"\n--- {label_name} (标签={label_id}) ---")
    count = 0
    for item in train_data:
        if item["label"] == label_id and count < 5:
            text = item["text"]
            print(f"  - {text}")
            count += 1
        if count >= 5:
            break

print()
print("=== 数据格式说明 ===")
print("每条数据包含两个字段:")
print("  - text: 文本内容 (字符串)")
print("  - label: 情绪标签 (0-5 的整数)")
print()
print("如果你要准备自己的数据集，格式如下:")
print("CSV 格式: text,label")
print("  i feel so happy today,1")
print("  this makes me angry,3")
print()
print("JSON 格式:")
print('  [{"text": "i feel so happy today", "label": 1}, ...]')
