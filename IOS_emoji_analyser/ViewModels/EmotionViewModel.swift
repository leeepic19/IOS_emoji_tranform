//
//  EmotionViewModel.swift
//  IOS_emoji_analyser
//
//  Created by 李玉广 on 2025/12/1.
//

import Foundation
import Combine

class EmotionViewModel: ObservableObject {
    @Published var currentEmotion: EmotionType = .neutral
    @Published var currentEmoji: String = "😐"
    @Published var recognizedText: String = ""
    @Published var isListening: Bool = false
    @Published var emotionHistory: [EmotionRecord] = []
    
    let permissionManager = PermissionManager()
    
    struct EmotionRecord: Identifiable {
        let id = UUID()
        let emotion: EmotionType
        let text: String
        let timestamp: Date
    }
    
    // MARK: - Control Methods
    func startListening() {
        guard permissionManager.allPermissionsGranted else {
            print("权限未授予，无法开始监听")
            return
        }
        
        isListening = true
        // TODO: 启动音频采集和语音识别
        print("开始监听...")
    }
    
    func stopListening() {
        isListening = false
        // TODO: 停止音频采集和语音识别
        print("停止监听...")
    }
    
    // MARK: - Emotion Update
    func updateEmotion(_ emotion: EmotionType, text: String) {
        currentEmotion = emotion
        currentEmoji = emotion.emoji
        recognizedText = text
        
        // 添加到历史记录
        let record = EmotionRecord(emotion: emotion, text: text, timestamp: Date())
        emotionHistory.insert(record, at: 0)
        
        // 限制历史记录数量
        if emotionHistory.count > Constants.maxHistoryCount {
            emotionHistory.removeLast()
        }
    }
    
    // MARK: - Test Method (for development)
    func simulateEmotion() {
        let emotions = EmotionType.allCases
        let randomEmotion = emotions.randomElement() ?? .neutral
        let testText = "测试文本：\(randomEmotion.rawValue)"
        updateEmotion(randomEmotion, text: testText)
    }
}
