//
//  PermissionManager.swift
//  IOS_emoji_analyser
//
//  Created by 李玉广 on 2025/12/1.
//

import Foundation
import AVFoundation
import Speech

class PermissionManager: ObservableObject {
    @Published var microphonePermissionGranted = false
    @Published var speechRecognitionPermissionGranted = false
    
    var allPermissionsGranted: Bool {
        return microphonePermissionGranted && speechRecognitionPermissionGranted
    }
    
    init() {
        checkPermissions()
    }
    
    // MARK: - Check Permissions
    func checkPermissions() {
        checkMicrophonePermission()
        checkSpeechRecognitionPermission()
    }
    
    private func checkMicrophonePermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            microphonePermissionGranted = true
        case .denied:
            microphonePermissionGranted = false
        case .undetermined:
            microphonePermissionGranted = false
        @unknown default:
            microphonePermissionGranted = false
        }
    }
    
    private func checkSpeechRecognitionPermission() {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            speechRecognitionPermissionGranted = true
        case .denied, .restricted, .notDetermined:
            speechRecognitionPermissionGranted = false
        @unknown default:
            speechRecognitionPermissionGranted = false
        }
    }
    
    // MARK: - Request Permissions
    func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.microphonePermissionGranted = granted
            }
        }
    }
    
    func requestSpeechRecognitionPermission() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.speechRecognitionPermissionGranted = (status == .authorized)
            }
        }
    }
    
    func requestAllPermissions() {
        requestMicrophonePermission()
        requestSpeechRecognitionPermission()
    }
}
