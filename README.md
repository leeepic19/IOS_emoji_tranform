# IOS Emoji Analyser

## 项目概述
一个实时检测语音聊天氛围情绪，并在屏幕上显示相应emoji的iOS应用程序。

## 功能描述
本应用通过实时语音分析，智能识别对话情绪，并以emoji形式直观展示情感状态。

## 核心功能模块

### 1. 语音输入模块 (Audio Input Module)
- **功能**: 获取麦克风权限并实时录制音频
- **技术栈**: 
  - `AVFoundation` - 音频采集
  - `Speech` - 语音识别权限管理
- **主要任务**:
  - 请求麦克风访问权限
  - 配置音频会话 (AVAudioSession)
  - 实时音频流采集
  - 音频数据缓冲管理

### 2. 语音转文字模块 (Speech-to-Text Module)
- **功能**: 将实时语音转换为文字
- **技术栈**:
  - `Speech Framework` - Apple原生语音识别
  - `SFSpeechRecognizer` - 语音识别器
  - `SFSpeechAudioBufferRecognitionRequest` - 实时识别请求
- **主要任务**:
  - 配置语音识别器（支持中文/英文）
  - 实时语音流转文字
  - 处理识别结果和错误
  - 文字缓冲区管理

### 3. 情绪分析模块 (Emotion Analysis Module)
- **功能**: 本地调用微调后的小模型预测文字情绪
- **技术栈**:
  - `Core ML` - Apple机器学习框架
  - `Create ML` / `PyTorch Mobile` - 模型训练和部署
  - 自定义情绪分类模型
- **主要任务**:
  - 加载本地ML模型
  - 文本预处理和特征提取
  - 情绪分类预测（如：开心、悲伤、愤怒、惊讶、中性等）
  - 返回情绪标签和置信度

### 4. Emoji显示模块 (Emoji Display Module)
- **功能**: 根据情绪分析结果在屏幕上显示对应emoji
- **技术栈**:
  - `SwiftUI` - UI界面构建
  - 动画效果 (SwiftUI Animations)
- **主要任务**:
  - 情绪到emoji的映射逻辑
  - emoji动态显示和切换
  - 视觉效果和动画
  - 历史情绪记录展示

## 技术架构

### 系统架构图
```
┌─────────────────────────────────────────────────────────┐
│                    User Interface (SwiftUI)              │
│                 - Emoji Display                          │
│                 - Permission Requests                    │
│                 - Settings                               │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                   Application Logic Layer                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Audio      │→ │  Speech-to-  │→ │   Emotion    │  │
│  │   Capture    │  │     Text     │  │   Analysis   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                    System Frameworks                     │
│   - AVFoundation                                         │
│   - Speech Framework                                     │
│   - Core ML                                              │
└─────────────────────────────────────────────────────────┘
```

### 数据流程
```
麦克风音频 → 音频缓冲区 → 语音识别 → 文本字符串 
    → 情绪分析模型 → 情绪标签 → Emoji映射 → UI显示
```

## 项目结构

```
IOS_emoji_analyser/
├── App/
│   ├── IOS_emoji_analyserApp.swift          # 应用入口
│   └── ContentView.swift                     # 主视图
├── Models/
│   ├── EmotionModel.mlmodel                  # Core ML情绪分析模型
│   ├── EmotionType.swift                     # 情绪类型枚举
│   └── EmojiMapper.swift                     # 情绪到Emoji映射
├── Services/
│   ├── AudioCaptureService.swift             # 音频采集服务
│   ├── SpeechRecognitionService.swift        # 语音识别服务
│   └── EmotionAnalysisService.swift          # 情绪分析服务
├── Views/
│   ├── EmojiDisplayView.swift                # Emoji显示视图
│   ├── PermissionView.swift                  # 权限请求视图
│   └── SettingsView.swift                    # 设置视图
├── ViewModels/
│   └── EmotionViewModel.swift                # 主视图模型
├── Utilities/
│   ├── PermissionManager.swift               # 权限管理
│   └── Constants.swift                       # 常量定义
└── Resources/
    └── Assets.xcassets/                      # 资源文件
```

## 开发路线图

### Phase 1: 基础架构搭建
- [ ] 项目初始化和基本UI框架
- [ ] 权限管理系统（麦克风、语音识别）
- [ ] 基础视图和导航结构

### Phase 2: 音频采集与语音识别
- [ ] 实现音频采集服务
- [ ] 集成Speech Framework
- [ ] 实时语音转文字功能
- [ ] 测试和优化识别准确率

### Phase 3: 情绪分析模型
- [ ] 准备训练数据集
- [ ] 训练/微调情绪分类模型
- [ ] 将模型转换为Core ML格式
- [ ] 集成模型到应用中
- [ ] 模型推理性能优化

### Phase 4: Emoji显示与UI优化
- [ ] 设计情绪到Emoji映射规则
- [ ] 实现Emoji动态显示
- [ ] 添加动画效果
- [ ] UI/UX优化

### Phase 5: 测试与发布
- [ ] 功能测试
- [ ] 性能优化
- [ ] Bug修复
- [ ] App Store准备

## 技术要点

### 权限管理
```swift
- NSMicrophoneUsageDescription (Info.plist)
- NSSpeechRecognitionUsageDescription (Info.plist)
```

### 性能优化
- 音频采集使用低延迟配置
- 异步处理语音识别
- 模型推理在后台线程执行
- 合理的内存管理和资源释放

### 情绪类别建议
- 😊 开心/快乐
- 😢 悲伤/难过
- 😡 愤怒/生气
- 😮 惊讶/震惊
- 😰 焦虑/担心
- 😐 中性/平静
- 😍 喜爱/兴奋
- 😴 疲惫/无聊

## 依赖项
- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

## 注意事项
1. 语音识别需要网络连接（Apple服务器）或设备端识别
2. Core ML模型需要针对iOS设备优化
3. 实时处理需要考虑性能和电量消耗
4. 需要处理用户隐私和数据安全

## 许可证
待定

## 作者
leeepic19

## 更新日志
- 2025/12/1: 项目初始化
