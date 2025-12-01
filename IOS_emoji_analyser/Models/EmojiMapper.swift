//
//  EmojiMapper.swift
//  IOS_emoji_analyser
//
//  Created by 李玉广 on 2025/12/1.
//

import Foundation

struct EmojiMapper {
    /// 根据情绪类型返回对应的emoji
    static func emoji(for emotion: EmotionType) -> String {
        return emotion.emoji
    }
    
    /// 根据情绪标签字符串返回EmotionType
    static func emotionType(from label: String) -> EmotionType {
        let lowercased = label.lowercased()
        
        // 中文匹配
        if lowercased.contains("开心") || lowercased.contains("快乐") || lowercased.contains("高兴") {
            return .happy
        } else if lowercased.contains("悲伤") || lowercased.contains("难过") || lowercased.contains("伤心") {
            return .sad
        } else if lowercased.contains("愤怒") || lowercased.contains("生气") || lowercased.contains("气愤") {
            return .angry
        } else if lowercased.contains("惊讶") || lowercased.contains("震惊") || lowercased.contains("吃惊") {
            return .surprised
        } else if lowercased.contains("焦虑") || lowercased.contains("担心") || lowercased.contains("紧张") {
            return .anxious
        } else if lowercased.contains("喜爱") || lowercased.contains("兴奋") || lowercased.contains("激动") {
            return .love
        } else if lowercased.contains("疲惫") || lowercased.contains("无聊") || lowercased.contains("困") {
            return .tired
        }
        
        // 英文匹配
        if lowercased.contains("happy") || lowercased.contains("joy") {
            return .happy
        } else if lowercased.contains("sad") || lowercased.contains("unhappy") {
            return .sad
        } else if lowercased.contains("angry") || lowercased.contains("anger") {
            return .angry
        } else if lowercased.contains("surprise") || lowercased.contains("shock") {
            return .surprised
        } else if lowercased.contains("anxious") || lowercased.contains("worry") {
            return .anxious
        } else if lowercased.contains("love") || lowercased.contains("excited") {
            return .love
        } else if lowercased.contains("tired") || lowercased.contains("bored") {
            return .tired
        }
        
        return .neutral
    }
}
