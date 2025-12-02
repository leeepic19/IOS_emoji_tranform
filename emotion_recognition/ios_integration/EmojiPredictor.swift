import Foundation
import CoreML

/// 实时情绪预测器 - 缓存10秒内最多20个字，预测对应的emoji
@MainActor
class EmojiPredictor: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentEmoji: String = ""
    @Published var confidence: Float = 0.0
    @Published var cachedText: String = ""
    @Published var isReady: Bool = false
    
    // MARK: - Configuration
    private let maxChars = 20
    private let cacheTimeout: TimeInterval = 10.0
    private let predictionInterval: TimeInterval = 0.5
    
    // MARK: - Private Properties
    private var model: EmojiPredictor_int8?
    private var vocab: [String: Int] = [:]
    private var emojiMap: [Int: String] = [:]
    private var charBuffer: [(char: Character, timestamp: Date)] = []
    private var predictionTimer: Timer?
    
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
        do {
            // 加载 CoreML 模型
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndNeuralEngine  // 使用 Neural Engine 加速
            model = try EmojiPredictor_int8(configuration: config)
            
            // 加载词表
            loadVocab()
            
            // 加载 emoji 映射
            loadEmojiMap()
            
            isReady = true
            print("✅ 模型加载完成")
            
            // 启动预测定时器
            startPredictionTimer()
            
        } catch {
            print("❌ 模型加载失败: \(error)")
        }
    }
    
    private func loadVocab() {
        guard let url = Bundle.main.url(forResource: "vocab", withExtension: "txt"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            print("⚠️ 无法加载 vocab.txt，使用字符级分词")
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
    func addText(_ text: String) {
        let now = Date()
        for char in text where !char.isWhitespace {
            charBuffer.append((char, now))
        }
        
        // 限制最大字数
        while charBuffer.count > maxChars {
            charBuffer.removeFirst()
        }
        
        // 立即触发预测
        performPrediction()
    }
    
    func clearCache() {
        charBuffer.removeAll()
        cachedText = ""
        currentEmoji = ""
        confidence = 0.0
    }
    
    // MARK: - Prediction
    private func startPredictionTimer() {
        predictionTimer = Timer.scheduledTimer(withTimeInterval: predictionInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.performPrediction()
            }
        }
    }
    
    private func performPrediction() {
        // 清除超时字符
        let now = Date()
        charBuffer.removeAll { now.timeIntervalSince($0.timestamp) > cacheTimeout }
        
        // 获取当前缓存文本
        cachedText = String(charBuffer.map { $0.char })
        
        guard cachedText.count >= 2, let model = model else { return }
        
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
            currentEmoji = emojiMap[maxIdx] ?? "❓"
            
        } catch {
            print("❌ 预测失败: \(error)")
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
                inputIds[idx] = Int32(vocab["[UNK]"] ?? 100)  // Unknown token
            }
            attentionMask[idx] = 1
            idx += 1
        }
        
        // [SEP] token
        inputIds[idx] = Int32(vocab["[SEP]"] ?? 102)
        attentionMask[idx] = 1
        
        return (inputIds, attentionMask)
    }
    
    deinit {
        predictionTimer?.invalidate()
    }
}
