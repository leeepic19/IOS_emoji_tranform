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
        isRecording = true
        
        // 异步启动识别
        Task {
            do {
                try await startRecognitionEngine()
            } catch {
                self.error = "启动失败: \(error.localizedDescription)"
                self.isRecording = false
            }
        }
    }
    
    /// 停止录音
    func stopRecording() {
        guard isRecording else { return }
        
        // 停止音频引擎
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        // 结束识别请求
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // 取消识别任务
        recognitionTask?.cancel()
        recognitionTask = nil
        
        audioEngine = nil
        isRecording = false
    }
    
    // MARK: - Private Methods
    
    private func startRecognitionEngine() async throws {
        // 确保有权限
        let hasPermission = await requestPermissions()
        guard hasPermission else {
            throw NSError(domain: "SpeechRecognition", code: -1, userInfo: [NSLocalizedDescriptionKey: "没有语音识别权限"])
        }
        
        // 停止之前的任务
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // ⚠️ 重要：配置音频会话 - 使用 playAndRecord 以便在模拟器上工作
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw NSError(domain: "SpeechRecognition", code: -3, userInfo: [NSLocalizedDescriptionKey: "无法配置音频会话: \(error.localizedDescription)"])
        }
        
        // 创建音频引擎 - 在配置音频会话之后
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw NSError(domain: "SpeechRecognition", code: -2, userInfo: [NSLocalizedDescriptionKey: "无法创建音频引擎"])
        }
        
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
        
        let inputNode = audioEngine.inputNode
        
        // ⚠️ 重要：使用 nil 格式让系统自动选择最佳格式
        // 这是在模拟器上最可靠的方式
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buffer, _ in
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
                
                if let error = error {
                    // 不显示错误提示,因为正常停止也会触发error
                    if (error as NSError).code != 216 { // 216 是正常取消的错误码
                        self.error = nil // 忽略错误提示
                    }
                    self.stopRecording()
                }
                
                // 识别完成
                if result?.isFinal == true {
                    self.stopRecording()
                }
            }
        }
    }
    
    private func requestPermissions() async -> Bool {
        // 请求麦克风权限
        let audioGranted = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        guard audioGranted else { return false }
        
        // 请求语音识别权限
        return await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}
