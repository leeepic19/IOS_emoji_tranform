//
//  EmojiDisplayView.swift
//  IOS_emoji_analyser
//

import SwiftUI

struct EmojiDisplayView: View {
    @ObservedObject var viewModel: EmotionViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                statusIndicator
                emojiDisplaySection
                if !viewModel.cachedText.isEmpty { analysisTextSection }
                voiceInputSection
                if let error = viewModel.errorMessage { errorSection(error: error) }
                if !viewModel.emotionHistory.isEmpty { historySection }
            }
            .padding()
        }
    }
    
    private var statusIndicator: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.isModelReady ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(viewModel.isModelReady ? "就绪" : "加载中")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if viewModel.isListening {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color.red.opacity(0.5), lineWidth: 2)
                                .scaleEffect(1.5)
                        )
                    Text("监听中")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
        }
    }
    
    private var emojiDisplaySection: some View {
        VStack(spacing: 12) {
            Text(viewModel.currentEmoji).font(.system(size: 80))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.currentEmoji)
            if viewModel.confidence > 0 {
                HStack(spacing: 6) {
                    Text("置信度:").font(.caption).foregroundColor(.secondary)
                    Text("\(Int(viewModel.confidence * 100))%").font(.caption).fontWeight(.bold).foregroundColor(.blue)
                }
            }
        }
        .padding().frame(maxWidth: .infinity).background(Color(.systemGray6)).cornerRadius(16)
    }
    
    private var analysisTextSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("分析文本").font(.caption).foregroundColor(.secondary)
                Spacer()
                Text("\(viewModel.cachedText.count)/20字 (10秒超时)").font(.caption2)
                    .foregroundColor(viewModel.cachedText.count >= 18 ? .orange : .secondary)
            }
            Text(viewModel.cachedText).font(.body).padding(10).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray5)).cornerRadius(10)
        }
    }
    
    private var voiceInputSection: some View {
        VStack(spacing: 12) {
            if !viewModel.recognizedText.isEmpty && viewModel.isListening {
                VStack(alignment: .leading, spacing: 4) {
                    Text("实时识别").font(.caption).foregroundColor(.secondary)
                    Text(viewModel.recognizedText).font(.body).padding(10).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray5)).cornerRadius(10)
                }
            }
            HStack(spacing: 16) {
                Button(action: { viewModel.isListening ? viewModel.stopListening() : viewModel.startListening() }) {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isListening ? "stop.circle.fill" : "mic.circle.fill").font(.title3)
                        Text(viewModel.isListening ? "停止" : "开始监听").fontWeight(.medium)
                    }
                    .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(viewModel.isListening ? Color.red : Color.blue).cornerRadius(12)
                }
                .disabled(!viewModel.isModelReady)
                Button(action: { viewModel.simulateEmotion() }) {
                    Image(systemName: "shuffle.circle.fill").font(.title2).foregroundColor(.white)
                        .frame(width: 50, height: 50).background(Color.green).cornerRadius(12)
                }
                .disabled(!viewModel.isModelReady)
            }
        }
    }
    
    private func errorSection(error: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
            Text(error).font(.caption).foregroundColor(.secondary)
            Spacer()
        }
        .padding(10).background(Color.orange.opacity(0.1)).cornerRadius(10)
    }
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("历史记录").font(.subheadline).fontWeight(.medium)
                Spacer()
                Button(action: { viewModel.clearHistory() }) { Text("清空").font(.caption).foregroundColor(.red) }
            }
            ForEach(viewModel.emotionHistory) { record in
                HStack {
                    Text(record.emoji).font(.title3)
                    Text(record.text).font(.caption).lineLimit(1)
                    Spacer()
                    Text(formatTime(record.timestamp)).font(.caption2).foregroundColor(.secondary)
                }
                .padding(8).background(Color(.systemGray6)).cornerRadius(8)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm:ss"; return f.string(from: date)
    }
}

#Preview { EmojiDisplayView(viewModel: EmotionViewModel()) }
