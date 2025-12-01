//
//  SettingsView.swift
//  IOS_emoji_analyser
//
//  Created by 李玉广 on 2025/12/1.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.openURL) var openURL
    
    var body: some View {
        List {
            Section(header: Text("关于")) {
                HStack {
                    Text("应用名称")
                    Spacer()
                    Text(Constants.appName)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("版本")
                    Spacer()
                    Text(Constants.version)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("权限")) {
                Button(action: {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        openURL(settingsUrl)
                    }
                }) {
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(.blue)
                        Text("管理权限")
                        Spacer()
                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            
            Section(header: Text("帮助")) {
                NavigationLink(destination: HelpView()) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.blue)
                        Text("使用说明")
                    }
                }
                
                NavigationLink(destination: AboutView()) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("关于项目")
                    }
                }
            }
            
            Section(header: Text("开发")) {
                HStack {
                    Image(systemName: "hammer")
                        .foregroundColor(.orange)
                    Text("开发者")
                    Spacer()
                    Text("leeepic19")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("使用说明")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("1. 授予权限")
                        .font(.headline)
                    Text("首次使用时，请授予麦克风和语音识别权限。")
                        .foregroundColor(.secondary)
                    
                    Text("2. 开始监听")
                        .font(.headline)
                    Text("点击\"开始监听\"按钮，应用将实时分析您的语音并显示对应的情绪emoji。")
                        .foregroundColor(.secondary)
                    
                    Text("3. 查看历史")
                        .font(.headline)
                    Text("在主界面可以查看最近的情绪分析历史记录。")
                        .foregroundColor(.secondary)
                    
                    Text("4. 停止监听")
                        .font(.headline)
                    Text("完成后点击\"停止监听\"按钮即可停止分析。")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("使用说明")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("关于项目")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("项目简介")
                        .font(.headline)
                    Text("这是一个实时检测语音聊天氛围情绪，并在屏幕上显示emoji的iOS应用程序。")
                        .foregroundColor(.secondary)
                    
                    Text("技术栈")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• SwiftUI - 用户界面")
                        Text("• AVFoundation - 音频采集")
                        Text("• Speech Framework - 语音识别")
                        Text("• Core ML - 情绪分析")
                    }
                    .foregroundColor(.secondary)
                    
                    Text("开发者")
                        .font(.headline)
                    Text("leeepic19")
                        .foregroundColor(.secondary)
                    
                    Text("版本")
                        .font(.headline)
                    Text(Constants.version)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
