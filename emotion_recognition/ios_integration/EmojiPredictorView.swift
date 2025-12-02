import SwiftUI

/// 实时情绪识别演示视图
struct EmojiPredictorView: View {
    @StateObject private var predictor = EmojiPredictor()
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 状态指示
                statusView
                
                // 预测结果
                predictionResultView
                
                // 缓存显示
                cacheDisplayView
                
                // 输入区域
                inputView
                
                Spacer()
            }
            .padding()
            .navigationTitle("情绪识别")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("清空") {
                        predictor.clearCache()
                        inputText = ""
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var statusView: some View {
        HStack {
            Circle()
                .fill(predictor.isReady ? Color.green : Color.orange)
                .frame(width: 12, height: 12)
            Text(predictor.isReady ? "模型已就绪" : "加载中...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var predictionResultView: some View {
        VStack(spacing: 8) {
            Text(predictor.currentEmoji.isEmpty ? "🎭" : predictor.currentEmoji)
                .font(.system(size: 100))
                .animation(.spring(response: 0.3), value: predictor.currentEmoji)
            
            if predictor.confidence > 0 {
                Text("置信度: \(Int(predictor.confidence * 100))%")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: 160)
    }
    
    private var cacheDisplayView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("缓存文本")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(predictor.cachedText.count)/20字")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(predictor.cachedText.isEmpty ? "等待输入..." : predictor.cachedText)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
    
    private var inputView: some View {
        VStack(spacing: 12) {
            TextField("输入文字...", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .focused($isInputFocused)
                .onSubmit {
                    submitText()
                }
            
            Button(action: submitText) {
                Text("发送")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(inputText.isEmpty)
        }
    }
    
    // MARK: - Actions
    
    private func submitText() {
        guard !inputText.isEmpty else { return }
        predictor.addText(inputText)
        inputText = ""
    }
}

// MARK: - Preview

#Preview {
    EmojiPredictorView()
}
