# iOS 情绪识别模型集成指南

## 📦 需要的文件

将以下文件添加到你的 Xcode 项目中：

```
output/
├── EmojiPredictor_int8.mlpackage  (113MB, CoreML模型)
├── vocab.txt                       (107KB, BERT词表)
└── emoji_map.json                  (264B, Emoji映射)
```

## 🚀 集成步骤

### 1. 添加 CoreML 模型

1. 在 Xcode 中，将 `EmojiPredictor_int8.mlpackage` 拖入项目
2. 确保 "Target Membership" 勾选你的 App
3. Xcode 会自动生成 `EmojiPredictor_int8.swift` 类

### 2. 添加资源文件

1. 将 `vocab.txt` 和 `emoji_map.json` 拖入项目
2. 确保它们被添加到 "Copy Bundle Resources" 中

### 3. 添加 Swift 代码

将以下文件添加到你的项目：
- `EmojiPredictor.swift` - 核心预测逻辑
- `EmojiPredictorView.swift` - SwiftUI 演示界面

### 4. 使用示例

```swift
import SwiftUI

@main
struct YourApp: App {
    var body: some Scene {
        WindowGroup {
            EmojiPredictorView()
        }
    }
}
```

或者在代码中直接使用：

```swift
let predictor = EmojiPredictor()

// 添加文本（模拟实时语音转文字）
predictor.addText("笑死我了")

// 获取预测结果
print(predictor.currentEmoji)    // "😂"
print(predictor.confidence)       // 0.987
print(predictor.cachedText)       // "笑死我了"

// 清空缓存
predictor.clearCache()
```

## ⚙️ 配置说明

在 `EmojiPredictor.swift` 中可以调整：

```swift
private let maxChars = 20              // 最大缓存字数
private let cacheTimeout: TimeInterval = 10.0   // 缓存超时(秒)
private let predictionInterval: TimeInterval = 0.5  // 预测间隔(秒)
```

## 🎭 支持的 Emoji

| ID | Emoji | 情绪 |
|----|-------|------|
| 0 | 😂 | 大笑 |
| 1 | 😄 | 开心 |
| 2 | 🥹 | 感动 |
| 3 | 😅 | 尴尬 |
| 4 | 😁 | 得意 |
| 5 | 🤓 | 认真/讲解 |
| 6 | 🥲 | 苦笑 |
| 7 | 😎 | 酷 |
| 8 | 🧐 | 疑惑 |
| 9 | 😱 | 惊恐 |
| 10 | 😡 | 愤怒 |
| 11 | 🫡 | 致敬 |
| 12 | 🥰 | 喜爱 |
| 13 | 😨 | 害怕 |
| 14 | 😠 | 生气 |
| 15 | 😑 | 无语 |
| 16 | 😭 | 大哭 |

## 📱 性能说明

- **模型大小**: 113 MB (INT8量化)
- **推理设备**: CPU + Neural Engine
- **推理延迟**: < 50ms (iPhone 12+)
- **内存占用**: ~150 MB

## 🔗 与语音识别集成

配合 Apple Speech Framework 使用：

```swift
import Speech

class SpeechRecognizer: ObservableObject {
    private let predictor = EmojiPredictor()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    
    func processTranscription(_ text: String) {
        // 实时将语音转文字结果传入预测器
        predictor.addText(text)
    }
}
```

## ❓ 常见问题

### Q: 模型加载失败？
确保 `.mlpackage` 文件正确添加到项目，且 Target Membership 已勾选。

### Q: 预测不准确？
- 确保输入文本至少2个字
- 检查 vocab.txt 是否正确加载
- 尝试增加输入文本长度

### Q: 如何减小包体积？
模型已使用 INT8 量化压缩到 113MB，如需更小可考虑：
1. 使用更小的基础模型 (如 DistilBERT)
2. 进一步剪枝

---

**模型信息**
- 基础模型: bert-base-chinese
- 训练数据: 546 条中文情绪文本
- 验证准确率: 46.6%
- 量化方式: INT8
