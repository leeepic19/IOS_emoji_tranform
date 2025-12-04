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
    
    // MARK: - Configuration
    private let maxChars = 20
    private let cacheTimeout: TimeInterval = 10.0
    
    // MARK: - Private Properties
    private var model: EmojiPredictor_int8?
    private var vocab: [String: Int] = [:]
    private var emojiMap: [Int: String] = [:]
    private var charBuffer: [(char: Character, timestamp: Date)] = []
    
    // 记录上一次处理的文本长度，用于计算增量
    private var lastProcessedLength: Int = 0
    
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
    
    // MARK: - Model Loading
    private func loadModel() async {
        print("📦 开始加载情绪预测模型...")
        do {
            // 加载 CoreML 模型
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndNeuralEngine
            model = try EmojiPredictor_int8(configuration: config)
            
            // 加载词表
            loadVocab()
            
            // 加载 emoji 映射
            loadEmojiMap()
            
            print("  - Emoji: \(emojiMap.count) 种")
            print("  - 词表: \(vocab.count) tokens")
            print("✅ 模型加载成功！")
            isReady = true
            print("✅ 情绪预测模型加载完成")
            
        } catch {
            self.error = "模型加载失败: \(error.localizedDescription)"
            print("❌ 模型加载失败: \(error)")
        }
    }
    
    private func loadVocab() {
        guard let url = Bundle.main.url(forResource: "vocab", withExtension: "txt"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            print("⚠️ 无法加载 vocab.txt")
            return
        }
        
        let lines = content.components(separatedBy: .newlines)
        for (index, token) in lines.enumerated() {
            if !token.isEmpty {
                vocab[token] = index
            }
        }
        print("📚 词表加载完成，共 \(vocab.count) 个token")
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
    
    /// 处理语音识别的累积文本（增量处理）
    /// - Parameter text: 语音识别返回的完整累积文本
    func processText(_ text: String) {
        let now = Date()
        
        // 过滤掉空白字符，得到纯文本
        let filteredText = text.filter { !$0.isWhitespace }
        let currentLength = filteredText.count
        
        // 只处理新增的字符（增量部分）
        if currentLength > lastProcessedLength {
            let startIndex = filteredText.index(filteredText.startIndex, offsetBy: lastProcessedLength)
            let newChars = filteredText[startIndex...]
            
            // 只添加新增的字符到缓存
            for char in newChars {
                charBuffer.append((char, now))
            }
            
            // 更新已处理长度
            lastProcessedLength = currentLength
        } else if currentLength < lastProcessedLength {
            // 如果文本变短了（可能是语音识别修正），重新处理
            // 清空缓存，重新添加所有字符
            charBuffer.removeAll()
            for char in filteredText {
                charBuffer.append((char, now))
            }
            lastProcessedLength = currentLength
        }
        // 如果长度相同，说明没有新字符，不做处理
        
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
    
    func clearCache() {
        charBuffer.removeAll()
        cachedText = ""
        currentEmoji = "😐"
        confidence = 0.0
        lastProcessedLength = 0  // 重置已处理长度
    }
    
    // MARK: - Prediction
    private func performPrediction() {
        guard cachedText.count >= 2, let model = model else {
            return
        }
        
        // 分词
        let (inputIds, attentionMask) = tokenize(cachedText)
        
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
            
            for i in 0..<17 {
                let val = logits[[0, i as NSNumber]].floatValue
                if val > maxVal {
                    maxVal = val
                    maxIdx = i
                }
            }
            
            // Softmax 计算置信度
            var expSum: Float = 0
            for i in 0..<17 {
                expSum += exp(logits[[0, i as NSNumber]].floatValue - maxVal)
            }
            confidence = 1.0 / expSum
            
            // 更新 emoji
            let newEmoji = emojiMap[maxIdx] ?? "❓"
            if newEmoji != currentEmoji {
                currentEmoji = newEmoji
            }
            
        } catch {
            print("❌ 预测失败: \(error)")
            self.error = "预测失败: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Tokenization
    private func tokenize(_ text: String) -> ([Int32], [Int32]) {
        var inputIds = [Int32](repeating: 0, count: 128)
        var attentionMask = [Int32](repeating: 0, count: 128)
        
        // [CLS] token
        inputIds[0] = Int32(vocab["[CLS]"] ?? 101)
        attentionMask[0] = 1
        
        var idx = 1
        for char in text {
            guard idx < 127 else { break }
            
            let token = String(char)
            if let tokenId = vocab[token] {
                inputIds[idx] = Int32(tokenId)
            } else {
                inputIds[idx] = Int32(vocab["[UNK]"] ?? 100)
            }
            attentionMask[idx] = 1
            idx += 1
        }
        
        // [SEP] token
        inputIds[idx] = Int32(vocab["[SEP]"] ?? 102)
        attentionMask[idx] = 1
        
        return (inputIds, attentionMask)
    }
}
