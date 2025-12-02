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
        VStack(spacing: 24) {
            // 模型状态指示器
            modelStatusView
            
            // 当前情绪Emoji显示
            VStack(spacing: 16) {
                Text(viewModel.currentEmoji)
                    .font(.system(size: 120))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.currentEmoji)
                    .scaleEffect(viewModel.isListening ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: viewModel.isListening)
                
                // 置信度显示
                if viewModel.confidence > 0 {
                    HStack(spacing: 8) {
                        Text("置信度:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(Int(viewModel.confidence * 100))%")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(20)
            
            // 缓存文本显示（模型处理的文本）
            if !viewModel.cachedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("分析文本")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(viewModel.cachedText.count)/20字")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(viewModel.cachedText)
                        .font(.body)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            
            // 实时识别文本显示
            if !viewModel.recognizedText.isEmpty && viewModel.isListening {
                VStack(alignment: .leading, spacing: 8) {
                    Text("实时识别")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        Text(viewModel.recognizedText)
                            .font(.body)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 80)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            
            // 错误信息显示
            if let error = viewModel.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("提示")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            // 控制按钮
            HStack(spacing: 20) {
                Button(action: {
                    if viewModel.isListening {
                        viewModel.stopListening()
                    } else {
                        viewModel.startListening()
                    }
                }) {
                    HStack(spacing: 8) {
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
                .disabled(!viewModel.isModelReady)
                
                // 测试按钮
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
                .disabled(!viewModel.isModelReady)
            }
            .padding(.horizontal)
            
            // 历史记录
            if !viewModel.emotionHistory.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("历史记录")
                            .font(.headline)
                        Spacer()
                        Button("清空") {
                            viewModel.clearHistory()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
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
    
    // MARK: - Subviews
    
    private var modelStatusView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Circle()
                    .fill(viewModel.isModelReady ? Color.green : Color.orange)
                    .frame(width: 10, height: 10)
                
                Text(viewModel.isModelReady ? "模型已就绪" : "加载模型中...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if viewModel.isListening {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .opacity(0.8)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: viewModel.isListening)
                        Text("监听中")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // 调试信息（开发阶段）
            #if DEBUG
            HStack(spacing: 8) {
                Text("权限:\(viewModel.permissionManager.allPermissionsGranted ? "✅" : "❌")")
                Text("模型:\(viewModel.isModelReady ? "✅" : "⏳")")
                Text("监听:\(viewModel.isListening ? "🔴" : "⚪️")")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
            #endif
        }
        .padding(.horizontal)
    }
}

struct EmotionHistoryRow: View {
    let record: EmotionViewModel.EmotionRecord
    
    var body: some View {
        HStack {
            Text(record.emoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(record.text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
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
