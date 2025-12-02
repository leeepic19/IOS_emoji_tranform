import Foundation
import Speech
import AVFoundation

/// 语音识别服务 - 实时将语音转换为文字
@MainActor
class SpeechRecognitionService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var recognizedText: String = ""
    @Published var isRecording: Bool = false
    @Published var error: String?
    
    // MARK: - Private Properties
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    
    // 文字回调
    var onTextRecognized: ((String) -> Void)?
    
    // MARK: - Public Methods
    
    /// 开始录音和识别
    func startRecording() {
        // 检查是否已经在录音
        guard !isRecording else { return }
        
        // 重置状态
        recognizedText = ""
        error = nil
        
        // 检查语音识别是否可用
        guard speechRecognizer?.isAvailable == true else {
            error = "语音识别服务不可用"
            return
        }
        
        do {
            try startRecognition()
            isRecording = true
            print("✅ 语音识别已启动")
        } catch {
            self.error = "启动识别失败: \(error.localizedDescription)"
            print("❌ 启动失败: \(error)")
        }
    }
    

    /// 停止录音和识别
    func stopRecording() {
        guard isRecording else { return }
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        
        isRecording = false
    }
    
    /// 清除文本
    func clearText() {
        recognizedText = ""
    }
    
    // MARK: - Private Methods
    
    private func startRecognition() throws {
        // 取消之前的任务
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // 配置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // 创建识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "SpeechRecognition", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法创建识别请求"])
        }
        
        // 配置请求
        recognitionRequest.shouldReportPartialResults = true
        
        // 支持实时识别（iOS 13+）
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        
        // 创建音频引擎
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw NSError(domain: "SpeechRecognition", code: -2, userInfo: [NSLocalizedDescriptionKey: "无法创建音频引擎"])
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // 安装音频tap
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // 准备并启动音频引擎
        audioEngine.prepare()
        try audioEngine.start()
        
        // 开始识别任务
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let result = result {
                    let transcription = result.bestTranscription.formattedString
                    self.recognizedText = transcription
                    
                    // 通知回调
                    self.onTextRecognized?(transcription)
                }
                
                // 只在真正出错且不是正常结束时显示错误
                if let error = error {
                    let nsError = error as NSError
                    // 忽略正常的识别结束错误（错误码 216 和 203）
                    if nsError.code != 216 && nsError.code != 203 {
                        print("⚠️ 语音识别错误: \(error.localizedDescription)")
                        // 只在用户主动停止前显示严重错误
                        if self.isRecording {
                            self.error = "识别错误: \(error.localizedDescription)"
                            self.stopRecording()
                        }
                    }
                }
                
                // 识别完成
                if result?.isFinal == true {
                    self.stopRecording()
                }
            }
        }
    }
    
    deinit {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }
}
