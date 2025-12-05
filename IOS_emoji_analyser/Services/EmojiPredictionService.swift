import Foundation
import CoreML

/// 情绪预测服务 - 使用CoreML模型预测文字情绪并返回emoji
@MainActor
class EmojiPredictionService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentEmoji: String = "😐"
    @Published var confidence: Float = 0.0
    @Published var cachedText: String = ""
    @Published var isReady: Bool = false
    @Published var error: String?
    @Published var debugInfo: String = ""
    @Published var detailedDebugLog: [String] = []  // 详细调试日志
    @Published var lastPredictionDetails: PredictionDetails?  // 最近一次预测详情
    @Published var vocabCount: Int = 0  // 词表大小
    @Published var vocabStatus: String = ""  // 词表状态
    
    // MARK: - Prediction Details
    struct PredictionDetails {
        let inputText: String
        let tokenIds: [Int32]
        let tokenCount: Int
        let allProbabilities: [(emoji: String, probability: Float)]
        let predictedClass: Int
        let predictedEmoji: String
        let confidence: Float
        let timestamp: Date
    }
    
    // MARK: - Configuration
    private let maxChars = 20
    private let cacheTimeout: TimeInterval = 10.0
    
    // MARK: - Private Properties
    private var model: EmojiPredictor_int8?
    private var vocab: [String: Int] = [:]
    private var emojiMap: [Int: String] = [:]
    private var charBuffer: [(char: Character, timestamp: Date)] = []
    
    // MARK: - Emoji Mapping
    private let defaultEmojiMap: [Int: String] = [
        0: "😂", 1: "😄", 2: "🥹", 3: "😅", 4: "😁",
        5: "🤓", 6: "🥲", 7: "😎", 8: "🧐", 9: "😱",
        10: "😡", 11: "🫡", 12: "🥰", 13: "😨", 14: "😠",
        15: "😑", 16: "😭"
    ]
    
    // MARK: - Initialization
    init() {
        Task {
            await loadModel()
        }
    }
    
    // MARK: - Debug Logging
    private func addDebugLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logEntry = "[\(timestamp)] \(message)"
        detailedDebugLog.append(logEntry)
        // 限制日志数量
        if detailedDebugLog.count > 100 {
            detailedDebugLog.removeFirst()
        }
        print("🔍 \(message)")
    }
    
    /// 获取最近的调试日志（用于复制）
    func getRecentLogs(count: Int = 20) -> String {
        return detailedDebugLog.suffix(count).joined(separator: "\n")
    }
    
    func clearDebugLog() {
        detailedDebugLog.removeAll()
        lastPredictionDetails = nil
    }
    
    // MARK: - Model Loading
    private func loadModel() async {
        addDebugLog("开始加载情绪预测模型...")
        print("📦 开始加载情绪预测模型...")
        do {
            // 加载 CoreML 模型
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndNeuralEngine
            model = try EmojiPredictor_int8(configuration: config)
            addDebugLog("CoreML模型加载成功")
            
            // 加载词表
            loadVocab()
            
            // 加载 emoji 映射
            loadEmojiMap()
            
            addDebugLog("Emoji: \(emojiMap.count)种, 词表: \(vocab.count) tokens")
            print("  - Emoji: \(emojiMap.count) 种")
            print("  - 词表: \(vocab.count) tokens")
            print("✅ 模型加载成功！")
            isReady = true
            debugInfo = "模型就绪 | 词表: \(vocab.count) | Emoji: \(emojiMap.count)"
            print("✅ 情绪预测模型加载完成")
            
        } catch {
            self.error = "模型加载失败: \(error.localizedDescription)"
            addDebugLog("❌ 模型加载失败: \(error.localizedDescription)")
            print("❌ 模型加载失败: \(error)")
        }
    }
    
    private func loadVocab() {
        guard let url = Bundle.main.url(forResource: "vocab", withExtension: "txt"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            vocabStatus = "❌ 无法加载 vocab.txt"
            addDebugLog("⚠️ 无法加载 vocab.txt")
            print("⚠️ 无法加载 vocab.txt")
            return
        }
        
        // 重要：只使用 \n 分割，不使用 .newlines
        // 因为 .newlines 会把 U+2028 (LINE SEPARATOR) 和 U+2029 (PARAGRAPH SEPARATOR) 
        // 也当作换行符，但这些字符本身是词表中的 token
        let lines = content.components(separatedBy: "\n")
        for (index, token) in lines.enumerated() {
            if !token.isEmpty {
                vocab[token] = index
            }
        }
        
        vocabCount = vocab.count
        
        // 调试：检查关键 token
        let testTokens = ["[CLS]", "[SEP]", "[UNK]", "[PAD]", "开", "心", "难", "过", "高", "兴"]
        var foundTokens: [String] = []
        var allFound = true
        for t in testTokens {
            if let id = vocab[t] {
                foundTokens.append("\(t):\(id)")
            } else {
                foundTokens.append("\(t):❌")
                allFound = false
            }
        }
        
        vocabStatus = allFound ? "✅ 词表加载成功 (\(vocab.count))" : "⚠️ 部分token缺失"
        addDebugLog("词表检查: \(foundTokens.joined(separator: ", "))")
        print("📚 词表加载完成，共 \(vocab.count) 个token")
        print("📚 关键token: \(foundTokens.joined(separator: ", "))")
    }
    
    private func loadEmojiMap() {
        guard let url = Bundle.main.url(forResource: "emoji_map", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            emojiMap = defaultEmojiMap
            print("⚠️ 使用默认 emoji 映射")
            return
        }
        
        for (key, emoji) in json {
            if let id = Int(key) {
                emojiMap[id] = emoji
            }
        }
        print("🎭 Emoji映射加载完成，共 \(emojiMap.count) 个")
    }
    
    // MARK: - Text Input
    func processText(_ text: String) {
        let now = Date()
        
        // 添加新字符
        for char in text where !char.isWhitespace {
            charBuffer.append((char, now))
        }
        
        // 限制最大字数
        while charBuffer.count > maxChars {
            charBuffer.removeFirst()
        }
        
        // 清除超时字符
        charBuffer.removeAll { now.timeIntervalSince($0.timestamp) > cacheTimeout }
        
        // 更新缓存文本
        cachedText = String(charBuffer.map { $0.char })
        
        // 执行预测
        performPrediction()
    }
    
    /// 直接测试函数 - 绕过缓存机制，直接用完整文本预测
    func directPredict(_ text: String) {
        guard text.count >= 2, let model = model else {
            addDebugLog("直接预测失败: 文本太短或模型未加载")
            return
        }
        
        addDebugLog("=== 直接预测测试 ===")
        addDebugLog("输入文本: \"\(text)\"")
        
        // 分词
        let (inputIds, attentionMask) = tokenize(text)
        
        // 记录有效token数量
        let validTokenCount = attentionMask.filter { $0 == 1 }.count
        addDebugLog("有效Token数: \(validTokenCount)")
        
        do {
            // 创建输入
            let inputIdsArray = try MLMultiArray(shape: [1, 128], dataType: .int32)
            let attentionMaskArray = try MLMultiArray(shape: [1, 128], dataType: .int32)
            
            for i in 0..<128 {
                inputIdsArray[i] = NSNumber(value: inputIds[i])
                attentionMaskArray[i] = NSNumber(value: attentionMask[i])
            }
            
            // 预测
            let input = EmojiPredictor_int8Input(input_ids: inputIdsArray, attention_mask: attentionMaskArray)
            let output = try model.prediction(input: input)
            
            // 解析结果
            let logits = output.logits
            var maxIdx = 0
            var maxVal: Float = -Float.infinity
            
            // 记录所有 logits
            var logitValues: [String] = []
            for i in 0..<17 {
                let val = logits[[0, i as NSNumber]].floatValue
                logitValues.append(String(format: "%.2f", val))
                if val > maxVal {
                    maxVal = val
                    maxIdx = i
                }
            }
            addDebugLog("Logits: [\(logitValues.joined(separator: ", "))]")
            
            // Softmax 计算所有类别的概率
            var expSum: Float = 0
            for i in 0..<17 {
                expSum += exp(logits[[0, i as NSNumber]].floatValue - maxVal)
            }
            let newConfidence = 1.0 / expSum
            
            // 计算所有类别的概率并排序
            var allProbabilities: [(emoji: String, probability: Float)] = []
            for i in 0..<17 {
                let prob = exp(logits[[0, i as NSNumber]].floatValue - maxVal) / expSum
                let emoji = emojiMap[i] ?? "❓"
                allProbabilities.append((emoji, prob))
            }
            allProbabilities.sort { $0.probability > $1.probability }
            
            // 更新结果
            let newEmoji = emojiMap[maxIdx] ?? "❓"
            
            // 记录详细结果
            let top5 = allProbabilities.prefix(5).map { "\($0.emoji):\(String(format: "%.1f", $0.probability * 100))%" }.joined(separator: " ")
            addDebugLog("预测类别: \(maxIdx), Emoji: \(newEmoji)")
            addDebugLog("置信度: \(String(format: "%.2f", newConfidence * 100))%")
            addDebugLog("Top5: \(top5)")
            addDebugLog("=== 测试完成 ===")
            
            // 更新 UI
            currentEmoji = newEmoji
            confidence = newConfidence
            cachedText = text
            
            lastPredictionDetails = PredictionDetails(
                inputText: text,
                tokenIds: Array(inputIds.prefix(validTokenCount)),
                tokenCount: validTokenCount,
                allProbabilities: allProbabilities,
                predictedClass: maxIdx,
                predictedEmoji: newEmoji,
                confidence: newConfidence,
                timestamp: Date()
            )
            
        } catch {
            addDebugLog("❌ 直接预测异常: \(error.localizedDescription)")
        }
    }
    
    func clearCache() {
        charBuffer.removeAll()
        cachedText = ""
        currentEmoji = "😐"
        confidence = 0.0
        addDebugLog("缓存已清空")
    }
    
    // MARK: - Prediction
    private func performPrediction() {
        guard cachedText.count >= 2, let model = model else {
            if cachedText.count < 2 {
                addDebugLog("文本太短(\(cachedText.count)字)，跳过预测")
            }
            return
        }
        
        addDebugLog("开始预测: \"\(cachedText)\"")
        
        // 分词
        let (inputIds, attentionMask) = tokenize(cachedText)
        
        // 记录有效token数量
        let validTokenCount = attentionMask.filter { $0 == 1 }.count
        addDebugLog("Token数量: \(validTokenCount), 输入长度: \(cachedText.count)字")
        
        do {
            // 创建输入
            let inputIdsArray = try MLMultiArray(shape: [1, 128], dataType: .int32)
            let attentionMaskArray = try MLMultiArray(shape: [1, 128], dataType: .int32)
            
            for i in 0..<128 {
                inputIdsArray[i] = NSNumber(value: inputIds[i])
                attentionMaskArray[i] = NSNumber(value: attentionMask[i])
            }
            
            // 记录前几个token用于调试
            let tokenPreview = inputIds.prefix(min(10, validTokenCount)).map { String($0) }.joined(separator: ",")
            addDebugLog("TokenIDs预览: [\(tokenPreview)...]")
            
            // 预测
            let input = EmojiPredictor_int8Input(input_ids: inputIdsArray, attention_mask: attentionMaskArray)
            let output = try model.prediction(input: input)
            
            // 解析结果
            let logits = output.logits
            var maxIdx = 0
            var maxVal: Float = -Float.infinity
            var allLogits: [(index: Int, value: Float)] = []
            
            for i in 0..<17 {
                let val = logits[[0, i as NSNumber]].floatValue
                allLogits.append((i, val))
                if val > maxVal {
                    maxVal = val
                    maxIdx = i
                }
            }
            
            // Softmax 计算所有类别的概率
            var expSum: Float = 0
            for i in 0..<17 {
                expSum += exp(logits[[0, i as NSNumber]].floatValue - maxVal)
            }
            confidence = 1.0 / expSum
            
            // 计算所有类别的概率并排序
            var allProbabilities: [(emoji: String, probability: Float)] = []
            for i in 0..<17 {
                let prob = exp(logits[[0, i as NSNumber]].floatValue - maxVal) / expSum
                let emoji = emojiMap[i] ?? "❓"
                allProbabilities.append((emoji, prob))
            }
            allProbabilities.sort { $0.probability > $1.probability }
            
            // 更新 emoji
            let newEmoji = emojiMap[maxIdx] ?? "❓"
            
            // 记录详细预测结果
            lastPredictionDetails = PredictionDetails(
                inputText: cachedText,
                tokenIds: Array(inputIds.prefix(validTokenCount)),
                tokenCount: validTokenCount,
                allProbabilities: allProbabilities,
                predictedClass: maxIdx,
                predictedEmoji: newEmoji,
                confidence: confidence,
                timestamp: Date()
            )
            
            // 构建调试信息
            let top3 = allProbabilities.prefix(3).map { "\($0.emoji):\(String(format: "%.1f", $0.probability * 100))%" }.joined(separator: " ")
            addDebugLog("预测结果: \(newEmoji) (类别\(maxIdx)) 置信度:\(String(format: "%.1f", confidence * 100))%")
            addDebugLog("Top3: \(top3)")
            
            // 更新调试信息显示
            debugInfo = "输入: \(cachedText)\n预测: \(newEmoji) (\(String(format: "%.1f", confidence * 100))%)\nTop3: \(top3)"
            
            if newEmoji != currentEmoji {
                addDebugLog("Emoji变化: \(currentEmoji) → \(newEmoji)")
                currentEmoji = newEmoji
            }
            
        } catch {
            let errorMsg = "预测失败: \(error.localizedDescription)"
            addDebugLog("❌ \(errorMsg)")
            self.error = errorMsg
        }
    }
    
    // MARK: - Tokenization
    private func tokenize(_ text: String) -> ([Int32], [Int32]) {
        var inputIds = [Int32](repeating: 0, count: 128)
        var attentionMask = [Int32](repeating: 0, count: 128)
        
        // [CLS] token - ID should be 101
        let clsId = vocab["[CLS]"] ?? 101
        inputIds[0] = Int32(clsId)
        attentionMask[0] = 1
        
        var idx = 1
        var tokenDetails: [String] = []
        
        for char in text {
            guard idx < 127 else { break }
            
            let token = String(char)
            let tokenId: Int
            if let id = vocab[token] {
                tokenId = id
                tokenDetails.append("'\(token)'→\(id)")
            } else {
                tokenId = vocab["[UNK]"] ?? 100
                tokenDetails.append("'\(token)'→UNK(\(tokenId))")
            }
            inputIds[idx] = Int32(tokenId)
            attentionMask[idx] = 1
            idx += 1
        }
        
        // [SEP] token - ID should be 102
        let sepId = vocab["[SEP]"] ?? 102
        inputIds[idx] = Int32(sepId)
        attentionMask[idx] = 1
        
        // 记录详细的分词信息
        addDebugLog("分词详情: [CLS](\(clsId)) \(tokenDetails.joined(separator: " ")) [SEP](\(sepId))")
        
        return (inputIds, attentionMask)
    }
}
