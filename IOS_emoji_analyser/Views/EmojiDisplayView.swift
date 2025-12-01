//
//  EmojiDisplayView.swift
//  IOS_emoji_analyser
//
//  Created by 李玉广 on 2025/12/1.
//

import SwiftUI

struct EmojiDisplayView: View {
    @ObservedObject var viewModel: EmotionViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            // 当前情绪Emoji显示
            VStack(spacing: 20) {
                Text(viewModel.currentEmoji)
                    .font(.system(size: Constants.emojiSize))
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: viewModel.currentEmoji)
                    .scaleEffect(viewModel.isListening ? 1.0 : 0.9)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: viewModel.isListening)
                
                Text(viewModel.currentEmotion.rawValue)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if !viewModel.recognizedText.isEmpty {
                    Text(viewModel.recognizedText)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .lineLimit(3)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(20)
            
            // 控制按钮
            HStack(spacing: 20) {
                Button(action: {
                    if viewModel.isListening {
                        viewModel.stopListening()
                    } else {
                        viewModel.startListening()
                    }
                }) {
                    HStack {
                        Image(systemName: viewModel.isListening ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.title2)
                        Text(viewModel.isListening ? "停止监听" : "开始监听")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isListening ? Color.red : Color.blue)
                    .cornerRadius(12)
                }
                
                // 测试按钮（开发用）
                Button(action: {
                    viewModel.simulateEmotion()
                }) {
                    Image(systemName: "shuffle.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.green)
                        .cornerRadius(12)
                }
            }
            
            // 历史记录
            if !viewModel.emotionHistory.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("历史记录")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(viewModel.emotionHistory) { record in
                                EmotionHistoryRow(record: record)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct EmotionHistoryRow: View {
    let record: EmotionViewModel.EmotionRecord
    
    var body: some View {
        HStack {
            Text(record.emotion.emoji)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(record.emotion.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(record.text)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(timeString(from: record.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

#Preview {
    EmojiDisplayView(viewModel: EmotionViewModel())
}
