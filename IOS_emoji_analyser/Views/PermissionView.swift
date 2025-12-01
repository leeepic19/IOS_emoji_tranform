//
//  PermissionView.swift
//  IOS_emoji_analyser
//
//  Created by 李玉广 on 2025/12/1.
//

import SwiftUI

struct PermissionView: View {
    @ObservedObject var permissionManager: PermissionManager
    @Environment(\.openURL) var openURL
    
    var body: some View {
        VStack(spacing: 30) {
            // 标题
            VStack(spacing: 10) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("需要权限")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("为了提供最佳体验，我们需要以下权限")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // 权限列表
            VStack(spacing: 20) {
                PermissionRow(
                    icon: "mic.fill",
                    title: "麦克风访问",
                    description: "实时录制音频进行分析",
                    isGranted: permissionManager.microphonePermissionGranted
                )
                
                PermissionRow(
                    icon: "waveform",
                    title: "语音识别",
                    description: "将语音转换为文字",
                    isGranted: permissionManager.speechRecognitionPermissionGranted
                )
            }
            .padding()
            
            Spacer()
            
            // 按钮
            VStack(spacing: 15) {
                if !permissionManager.allPermissionsGranted {
                    Button(action: {
                        permissionManager.requestAllPermissions()
                    }) {
                        Text("授予权限")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            openURL(settingsUrl)
                        }
                    }) {
                        Text("前往设置")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
        }
        .padding()
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isGranted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isGranted ? .green : .gray)
                .font(.title3)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    PermissionView(permissionManager: PermissionManager())
}
