//
//  DebugTestView.swift
//  IOS_emoji_analyser
//
//  专用调试界面 - 用于测试文字输入和查看详细的模型预测信息
//

import SwiftUI

struct DebugTestView: View {
    @ObservedObject var viewModel: EmotionViewModel
    @State private var testInput: String = ""
    @State private var showAllProbabilities: Bool = false
    @FocusState private var isInputFocused: Bool
    
    // 预设测试文本
    private let testCases: [(text: String, expectedEmoji: String)] = [
        ("哈哈哈笑死我了", "😂"),
        ("太开心了", "😄"),
        ("好感动啊", "🥹"),
        ("有点尴尬", "😅"),
        ("太棒了", "😁"),
        ("学到了", "🤓"),
        ("苦中作乐", "🥲"),
        ("太酷了", "😎"),
        ("让我想想", "🧐"),
        ("吓死我了", "😱"),
        ("气死我了", "😡"),
        ("收到明白", "🫡"),
        ("好喜欢你", "🥰"),
        ("好害怕", "😨"),
        ("真讨厌", "😠"),
        ("无语了", "😑"),
        ("好难过想哭", "😭"),
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 状态指示器
                    statusSection
                    
                    // 文字输入区
                    textInputSection
                    
                    // 当前预测结果
                    if viewModel.lastPredictionDetails != nil {
                        predictionResultSection
                    }
                    
                    // 概率分布
                    if showAllProbabilities, let details = viewModel.lastPredictionDetails {
                        probabilityDistributionSection(details: details)
                    }
                    
                    // 预设测试用例
                    testCasesSection
                    
                    // 调试日志
                    debugLogSection
                }
                .padding()
            }
            .navigationTitle("🔧 调试测试")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("复制日志") {
                        let logs = viewModel.detailedDebugLog.suffix(30).joined(separator: "\n")
                        UIPasteboard.general.string = logs
                    }
                    .font(.caption)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("清空日志") {
                        viewModel.detailedDebugLog.removeAll()
                    }
                    .font(.caption)
                }
            }
        }
    }
    
    // MARK: - 状态指示
    private var statusSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                StatusBadge(
                    title: "模型",
                    isActive: viewModel.isModelReady,
                    activeColor: .green
                )
                StatusBadge(
                    title: "词表",
                    isActive: viewModel.vocabCount > 0,
                    activeColor: .blue
                )
                StatusBadge(
                    title: "Emoji映射",
                    isActive: viewModel.isModelReady,
                    activeColor: .purple
                )
            }
            
            // 词表详情
            VStack(alignment: .leading, spacing: 4) {
                Text("词表状态: \(viewModel.vocabStatus)")
                    .font(.system(size: 11, design: .monospaced))
                Text("词表大小: \(viewModel.vocabCount) tokens")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(viewModel.vocabCount > 20000 ? .green : .red)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 文字输入区
    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📝 输入测试文本")
                .font(.headline)
            
            HStack {
                TextField("输入文字进行情绪识别测试...", text: $testInput)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .focused($isInputFocused)
                
                // 普通测试按钮
                Button(action: {
                    if !testInput.isEmpty {
                        viewModel.processManualInput(testInput)
                    }
                }) {
                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(viewModel.isModelReady ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!viewModel.isModelReady || testInput.isEmpty)
                
                // 直接测试按钮（绕过缓存）
                Button(action: {
                    if !testInput.isEmpty {
                        viewModel.directPredict(testInput)
                    }
                }) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(viewModel.isModelReady ? Color.orange : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!viewModel.isModelReady || testInput.isEmpty)
            }
            
            Text("蓝色▶️=普通测试(带缓存) | 橙色⚡=直接测试(无缓存)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            HStack {
                Button("清空输入") {
                    testInput = ""
                    viewModel.clearManualInput()
                }
                .font(.caption)
                .foregroundColor(.red)
                
                Spacer()
                
                Text("缓存: \(viewModel.cachedText.count)/20字")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - 预测结果区
    private var predictionResultSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🎯 预测结果")
                    .font(.headline)
                Spacer()
                Button(action: { showAllProbabilities.toggle() }) {
                    Text(showAllProbabilities ? "收起详情" : "展开详情")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if let details = viewModel.lastPredictionDetails {
                HStack(spacing: 20) {
                    // Emoji 显示
                    VStack {
                        Text(details.predictedEmoji)
                            .font(.system(size: 60))
                        Text("类别 \(details.predictedClass)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                        .frame(height: 80)
                    
                    // 详细信息
                    VStack(alignment: .leading, spacing: 6) {
                        InfoRow(label: "输入文本", value: details.inputText)
                        InfoRow(label: "Token数", value: "\(details.tokenCount)")
                        InfoRow(label: "置信度", value: String(format: "%.2f%%", details.confidence * 100))
                        InfoRow(label: "预测时间", value: formatTime(details.timestamp))
                    }
                }
                
                // Top 3 概率
                HStack(spacing: 8) {
                    ForEach(Array(details.allProbabilities.prefix(3).enumerated()), id: \.offset) { index, item in
                        VStack(spacing: 4) {
                            Text(item.emoji)
                                .font(.title2)
                            Text(String(format: "%.1f%%", item.probability * 100))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(index == 0 ? .blue : .secondary)
                        }
                        .padding(8)
                        .background(index == 0 ? Color.blue.opacity(0.2) : Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - 概率分布
    private func probabilityDistributionSection(details: EmojiPredictionService.PredictionDetails) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📊 完整概率分布")
                .font(.headline)
            
            ForEach(Array(details.allProbabilities.enumerated()), id: \.offset) { index, item in
                HStack {
                    Text(item.emoji)
                        .font(.title3)
                        .frame(width: 30)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .frame(height: 20)
                            
                            Rectangle()
                                .fill(index == 0 ? Color.blue : Color.gray)
                                .frame(width: geometry.size.width * CGFloat(item.probability), height: 20)
                        }
                        .cornerRadius(4)
                    }
                    .frame(height: 20)
                    
                    Text(String(format: "%5.2f%%", item.probability * 100))
                        .font(.system(size: 11, design: .monospaced))
                        .frame(width: 60, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - 预设测试用例
    private var testCasesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🧪 预设测试用例")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                ForEach(testCases, id: \.text) { testCase in
                    Button(action: {
                        testInput = testCase.text
                        viewModel.processManualInput(testCase.text)
                    }) {
                        VStack(spacing: 4) {
                            Text(testCase.expectedEmoji)
                                .font(.title2)
                            Text(testCase.text)
                                .font(.caption2)
                                .lineLimit(1)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .disabled(!viewModel.isModelReady)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - 调试日志
    private var debugLogSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("📋 调试日志")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.detailedDebugLog.count) 条")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(viewModel.detailedDebugLog.reversed().enumerated()), id: \.offset) { _, log in
                        Text(log)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                }
            }
            .frame(maxHeight: 200)
            .padding(8)
            .background(Color.black.opacity(0.05))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}

// MARK: - 辅助视图
struct StatusBadge: View {
    let title: String
    let isActive: Bool
    let activeColor: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(isActive ? activeColor : Color.gray)
                .frame(width: 12, height: 12)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    DebugTestView(viewModel: EmotionViewModel())
}
