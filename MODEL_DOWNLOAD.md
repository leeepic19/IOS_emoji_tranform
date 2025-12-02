# 模型文件说明

## 📦 为什么模型文件不在仓库中？

由于模型文件过大（约500MB），超过了GitHub的文件大小限制，因此没有包含在Git仓库中。

## 📥 如何获取模型文件

### 方案一：从训练机器复制（推荐）

如果您有访问训练模型的Ubuntu机器的权限，可以直接复制模型文件：

```bash
# 从训练机器复制到本地
scp -r username@ubuntu-machine:/path/to/model/* ./IOS_emoji_analyser/output/
```

### 方案二：使用Git LFS（大文件存储）

如果需要在Git中管理大文件，可以使用Git LFS：

```bash
# 安装 Git LFS
brew install git-lfs
git lfs install

# 跟踪大文件
git lfs track "*.mlpackage"
git lfs track "*.safetensors"

# 提交
git add .gitattributes
git add IOS_emoji_analyser/output/
git commit -m "添加模型文件（使用Git LFS）"
git push origin main
```

### 方案三：使用云存储服务

将模型文件上传到云存储服务（如Google Drive、百度网盘等），然后分享下载链接。

## 📂 需要的模型文件结构

```
IOS_emoji_analyser/output/
├── EmojiPredictor_int8.mlpackage/          # CoreML模型（98MB）
│   ├── Data/
│   │   └── com.apple.CoreML/
│   │       ├── model.mlmodel
│   │       └── weights/
│   │           └── weight.bin
│   └── Manifest.json
├── emoji_model/                             # 原始BERT模型（可选）
│   ├── config.json
│   ├── model.safetensors                    # (390MB)
│   ├── special_tokens_map.json
│   ├── tokenizer.json
│   ├── tokenizer_config.json
│   └── vocab.txt
├── emoji_map.json                           # Emoji映射文件
├── model_config.json                        # 模型配置
└── vocab.txt                                # BERT词表（必需）
```

## ✅ 必需文件（小文件，已包含在仓库中）

这些文件已经包含在Git仓库中：

- ✅ `vocab.txt` (107KB) - BERT词表
- ✅ `emoji_map.json` (264B) - Emoji映射
- ✅ `model_config.json` - 模型配置信息

## 🔴 需要单独获取的大文件

这些文件因为太大没有包含在仓库中：

- ⬇️ `EmojiPredictor_int8.mlpackage/` (98MB) - **必需**，CoreML模型
- ⬇️ `emoji_model/model.safetensors` (390MB) - 可选，原始PyTorch模型

## 🚀 快速设置步骤

1. **克隆仓库**
   ```bash
   git clone https://github.com/leeepic19/IOS_emoji_tranform.git
   cd IOS_emoji_tranform
   ```

2. **创建output目录**（如果不存在）
   ```bash
   mkdir -p IOS_emoji_analyser/output
   ```

3. **放置模型文件**
   - 将 `EmojiPredictor_int8.mlpackage` 复制到 `IOS_emoji_analyser/output/` 目录
   - 确保文件结构正确

4. **在Xcode中添加模型**
   - 打开 `IOS_emoji_analyser.xcodeproj`
   - 将 `EmojiPredictor_int8.mlpackage` 拖入项目
   - 确保勾选 "Add to targets: IOS_emoji_analyser"

5. **构建并运行**
   ```bash
   # 在Xcode中按 ⌘R 运行
   # 或使用命令行
   xcodebuild -project IOS_emoji_analyser.xcodeproj -scheme IOS_emoji_analyser build
   ```

## 📝 注意事项

- 模型文件 `EmojiPredictor_int8.mlpackage` 是**必需的**，应用无法在没有它的情况下运行
- 其他 `emoji_model/` 目录下的文件是可选的，仅在重新训练或转换模型时需要
- 小文件（vocab.txt, emoji_map.json）已经包含在仓库中，无需额外下载

## 🔗 相关文档

- [Phase 2 完成报告](PHASE2_COMPLETE.md)
- [项目架构](ARCHITECTURE.md)
- [快速开始指南](QUICKSTART.md)

## ❓ 常见问题

### Q: 为什么不使用Git LFS？
A: Git LFS需要额外的配置和存储费用。对于个人项目，直接从训练机器复制文件更简单。

### Q: 没有模型文件可以运行吗？
A: 不可以。情绪预测功能依赖CoreML模型。但您可以先运行Phase 1的代码查看UI框架。

### Q: 如何重新训练模型？
A: 请参考训练机器上的训练脚本，或查看 `ios_integration/README.md` 了解模型转换流程。

---

**最后更新：** 2024年12月2日
