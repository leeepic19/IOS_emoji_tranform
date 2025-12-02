# 构建错误修复指南

## 🔴 当前错误

```
error: Multiple commands produce '/Users/.../vocab.txt'
```

**原因：** 项目中有两个 `vocab.txt` 文件被添加到构建目标：
- `/output/vocab.txt`
- `/output/emoji_model/vocab.txt`

---

## ✅ 快速修复（3步）

### 方法1：在 Xcode 中移除重复文件（推荐）

1. **打开 Xcode**
   - 找到左侧项目导航器中的 `emoji_model` 文件夹

2. **找到重复的 vocab.txt**
   - 展开 `output` → `emoji_model`
   - 找到其中的 `vocab.txt` 文件

3. **移除引用**
   - 右键点击 `emoji_model/vocab.txt`
   - 选择 "Delete"
   - **重要：选择 "Remove Reference"**（不要选 "Move to Trash"）

4. **清理并构建**
   - 按 ⇧⌘K (Shift + Cmd + K) 清理
   - 按 ⌘B (Cmd + B) 构建

---

### 方法2：命令行修复（如果Xcode中找不到）

如果在 Xcode 中找不到重复的文件，可以尝试：

1. **查看哪些文件在项目中**
```bash
cd /Users/liyuguang/Desktop/IOS_emoji_analyser
grep -r "vocab.txt" IOS_emoji_analyser.xcodeproj/project.pbxproj
```

2. **在 Finder 中查看**
```bash
open /Users/liyuguang/Desktop/IOS_emoji_analyser/IOS_emoji_analyser/output/emoji_model
```

3. **确保只保留根目录的 vocab.txt**
   - 保留: `output/vocab.txt`
   - 移除引用: `output/emoji_model/vocab.txt`

---

## 📋 需要添加的文件清单

确保以下文件已正确添加到项目：

### ✅ 必需的资源文件

1. **EmojiPredictor_int8.mlpackage**
   - 位置: `output/EmojiPredictor_int8.mlpackage`
   - 大小: ~113 MB
   - 类型: CoreML 模型

2. **vocab.txt**
   - 位置: `output/vocab.txt`
   - 大小: ~107 KB
   - 类型: Text file

3. **emoji_map.json**
   - 位置: `output/emoji_map.json`
   - 大小: ~264 B
   - 类型: JSON file

### ✅ 必需的 Swift 文件

1. **SpeechRecognitionService.swift**
   - 位置: `Services/SpeechRecognitionService.swift`

2. **EmojiPredictionService.swift**
   - 位置: `Services/EmojiPredictionService.swift`

3. **EmotionViewModel.swift** (已更新)
   - 位置: `ViewModels/EmotionViewModel.swift`

4. **EmojiDisplayView.swift** (已更新)
   - 位置: `Views/EmojiDisplayView.swift`

---

## 🔍 验证文件是否正确添加

### 在 Xcode 中验证：

1. **点击项目名称**（蓝色图标）
2. **选择 TARGETS → IOS_emoji_analyser**
3. **点击 "Build Phases" 标签**
4. **展开 "Copy Bundle Resources"**
5. **检查列表中应该包含：**
   - ✅ `EmojiPredictor_int8.mlpackage`
   - ✅ `vocab.txt` (只有一个！)
   - ✅ `emoji_map.json`

### 如果看到两个 vocab.txt：

在 "Copy Bundle Resources" 列表中：
- 选中重复的 `vocab.txt`
- 点击下方的 `-` 号移除

---

## 🎯 完成后的测试

1. **清理构建**
```bash
⇧⌘K (Shift + Command + K)
```

2. **构建项目**
```bash
⌘B (Command + B)
```

3. **运行项目**
```bash
⌘R (Command + R)
```

### 预期结果：

✅ 构建成功，无错误
✅ 应用启动
✅ 顶部显示"加载模型中..."然后变为"模型已就绪"
✅ 可以点击测试按钮看到emoji变化

---

## 💡 提示

- 如果问题持续，尝试重启 Xcode
- 检查 DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/IOS_emoji_analyser-*`
- 确保所有文件的 Target Membership 正确设置

---

**修复完成后，继续查看 `PHASE2_COMPLETE.md` 了解功能测试步骤。**
