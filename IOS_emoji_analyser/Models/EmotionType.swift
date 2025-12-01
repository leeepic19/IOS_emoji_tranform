//
//  EmotionType.swift
//  IOS_emoji_analyser
//
//  Created by 李玉广 on 2025/12/1.
//

import Foundation

enum EmotionType: String, CaseIterable {
    case happy = "开心"
    case sad = "悲伤"
    case angry = "愤怒"
    case surprised = "惊讶"
    case anxious = "焦虑"
    case neutral = "平静"
    case love = "喜爱"
    case tired = "疲惫"
    
    var emoji: String {
        switch self {
        case .happy:
            return "😊"
        case .sad:
            return "😢"
        case .angry:
            return "😡"
        case .surprised:
            return "😮"
        case .anxious:
            return "😰"
        case .neutral:
            return "😐"
        case .love:
            return "😍"
        case .tired:
            return "😴"
        }
    }
    
    var color: String {
        switch self {
        case .happy, .love:
            return "yellow"
        case .sad, .tired:
            return "blue"
        case .angry:
            return "red"
        case .surprised:
            return "orange"
        case .anxious:
            return "purple"
        case .neutral:
            return "gray"
        }
    }
}
