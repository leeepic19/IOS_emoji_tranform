//
//  Constants.swift
//  IOS_emoji_analyser
//
//  Created by 李玉广 on 2025/12/1.
//

import Foundation

struct Constants {
    // MARK: - App Info
    static let appName = "Emoji Analyser"
    static let version = "1.0.0"
    
    // MARK: - Permission Messages
    static let microphonePermissionTitle = "需要麦克风权限"
    static let microphonePermissionMessage = "为了实时分析语音情绪，我们需要访问您的麦克风"
    
    static let speechRecognitionPermissionTitle = "需要语音识别权限"
    static let speechRecognitionPermissionMessage = "为了将语音转换为文字，我们需要使用语音识别功能"
    
    // MARK: - UI Constants
    static let emojiSize: CGFloat = 120
    static let animationDuration: Double = 0.3
    static let maxHistoryCount: Int = 10
    
    // MARK: - Model Constants
    static let modelName = "EmotionModel"
    static let confidenceThreshold: Float = 0.6
}
