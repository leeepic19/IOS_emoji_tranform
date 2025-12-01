# 🎯 快速配置权限 - 复制粘贴指南

## 第1步：打开项目设置
1. 在 Xcode 中点击最顶部的项目名称（蓝色图标）
2. 确保选择了 **TARGETS** → **IOS_emoji_analyser**
3. 点击 **Info** 标签页

## 第2步：添加权限

### 麦克风权限
**Key (复制这个):**
```
Privacy - Microphone Usage Description
```

**Value (复制这个):**
```
我们需要访问您的麦克风来实时录制语音，以便进行情绪分析
```

### 语音识别权限
**Key (复制这个):**
```
Privacy - Speech Recognition Usage Description
```

**Value (复制这个):**
```
我们需要使用语音识别功能将您的语音转换为文字，以便分析情绪
```

## 第3步：构建运行
```
⇧⌘K  - 清理
⌘B   - 构建
⌘R   - 运行
```

---

## 💡 提示

### 如果找不到这些 Key：
可以直接输入原始 Key 名称：
- `NSMicrophoneUsageDescription`
- `NSSpeechRecognitionUsageDescription`

Xcode 会自动显示为友好的名称。

### 如何添加：
1. 在 Custom iOS Target Properties 列表底部
2. 鼠标悬停会出现 **+** 按钮
3. 点击 **+** 
4. 输入或选择 Key
5. 在右侧输入 Value
6. 重复以上步骤添加第二个权限

---

**就是这么简单！配置完成后就可以运行了！** 🚀
