//
//  EmotionViewModel.swift
//  IOS_emoji_analyser
//
//  Created by 李玉广 on 2025/12/1.
//

import Foundation
import Combine

@MainActor
class EmotionViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentEmoji: String = "😐"
    @Published var recognizedText: String = ""
    @Published var cachedText: String = ""
    @Published var confidence: Float = 0.0
    @Published var isListening: Bool = false
    @Published var emotionHistory: [EmotionRecord] = []
    @Published var isModelReady: Bool = false
    @Published var errorMessage: String?
    @Published var debugInfo: String = ""
    @Published var detailedDebugLog: [String] = []  // 详细调试日志
    @Published var lastPredictionDetails: EmojiPredictionService.PredictionDetails?  // 最近预测详情
    @Published var vocabCount: Int = 0  // 词表大小
    @Published var vocabStatus: String = ""  // 词表状态
    
    // MARK: - Services
    let permissionManager = PermissionManager()
    private let speechService = SpeechRecognitionService()
    private let predictionService = EmojiPredictionService()
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Emotion Record
    struct EmotionRecord: Identifiable {
        let id = UUID()
        let emoji: String
        let text: String
        let timestamp: Date
    }
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // 监听语音识别结果
        speechService.$recognizedText
            .sink { [weak self] text in
                guard let self = self else { return }
                self.recognizedText = text
                // 将识别的文字传给情绪预测服务
                self.predictionService.processText(text)
            }
            .store(in: &cancellables)
        
        // 监听语音识别状态
        speechService.$isRecording
            .assign(to: &$isListening)
        
        // 监听预测服务的emoji结果
        predictionService.$currentEmoji
            .sink { [weak self] emoji in
                guard let self = self else { return }
                if self.currentEmoji != emoji {
                    self.currentEmoji = emoji
                }
            }
            .store(in: &cancellables)
        
        // 监听缓存文本
        predictionService.$cachedText
            .assign(to: &$cachedText)
        
        // 监听置信度
        predictionService.$confidence
            .assign(to: &$confidence)
        
        // 监听模型就绪状态
        predictionService.$isReady
            .assign(to: &$isModelReady)
        
        // 监听调试信息
        predictionService.$debugInfo
            .assign(to: &$debugInfo)
        
        // 监听详细调试日志
        predictionService.$detailedDebugLog
            .assign(to: &$detailedDebugLog)
        
        // 监听最近预测详情
        predictionService.$lastPredictionDetails
            .assign(to: &$lastPredictionDetails)
        
        // 监听词表状态
        predictionService.$vocabCount
            .assign(to: &$vocabCount)
        predictionService.$vocabStatus
            .assign(to: &$vocabStatus)
        
        // 监听错误
        Publishers.Merge(
            speechService.$error.compactMap { $0 },
            predictionService.$error.compactMap { $0 }
        )
        .sink { [weak self] error in
            self?.errorMessage = error
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Control Methods
    func startListening() {
        print("🔵 startListening 被调用")
        print("  - 权限状态: \(permissionManager.allPermissionsGranted)")
        print("  - 模型状态: \(isModelReady)")
        
        guard permissionManager.allPermissionsGranted else {
            errorMessage = "需要麦克风和语音识别权限"
            print("❌ 权限未授予")
            return
        }
        
        guard isModelReady else {
            errorMessage = "模型尚未加载完成，请稍候..."
            print("❌ 模型未就绪")
            return
        }
        
        // 清空之前的数据
        clearCurrentSession()
        
        // 启动语音识别
        print("🎤 启动语音识别服务...")
        speechService.startRecording()
        print("✅ 已调用 speechService.startRecording()")
    }
    
    func stopListening() {
        speechService.stopRecording()
        
        // 保存到历史记录
        if !cachedText.isEmpty {
            addToHistory()
        }
        
        print("⏸️ 停止监听")
    }
    
    func clearCurrentSession() {
        recognizedText = ""
        predictionService.clearCache()
        errorMessage = nil
    }
    
    func clearHistory() {
        emotionHistory.removeAll()
    }
    
    // MARK: - History Management
    private func addToHistory() {
        let record = EmotionRecord(
            emoji: currentEmoji,
            text: cachedText,
            timestamp: Date()
        )
        emotionHistory.insert(record, at: 0)
        
        // 限制历史记录数量
        if emotionHistory.count > Constants.maxHistoryCount {
            emotionHistory.removeLast()
        }
    }
    
    /// 直接测试 - 绕过缓存机制（供调试界面使用）
    func directPredict(_ text: String) {
        print("🔬 直接预测测试: \(text)")
        predictionService.directPredict(text)
    }
    
    /// 处理文本输入（供调试界面使用）
    func processManualInput(_ text: String) {
        print("⌨️ 调试输入: \(text)")
        predictionService.processText(text)
    }
    
    /// 清空缓存（供调试界面使用）
    func clearManualInput() {
        predictionService.clearCache()
        print("🗑️ 清空输入缓存")
    }
    
    func clearDebugLog() {
        predictionService.clearDebugLog()
        print("🗑️ 清空调试日志")
    }
    
    // MARK: - Test Methods
    func simulateEmotion() {
        let testTexts = [
            "哈哈哈笑死我了",
            "太开心了",
            "好感动啊",
            "有点尴尬",
            "太生气了",
            "害怕极了",
            "无语了",
            "好酷啊"
        ]
        
        let randomText = testTexts.randomElement() ?? "测试"
        recognizedText = randomText
        predictionService.processText(randomText)
    }
}
