//
//  ContentView.swift
//  IOS_emoji_analyser
//
//  Created by 李玉广 on 2025/12/1.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = EmotionViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.permissionManager.allPermissionsGranted {
                    // 主界面 - 权限已授予
                    EmojiDisplayView(viewModel: viewModel)
                        .navigationTitle("Emoji 情绪分析")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                NavigationLink(destination: SettingsView()) {
                                    Image(systemName: "gear")
                                }
                            }
                        }
                } else {
                    // 权限请求界面
                    PermissionView(permissionManager: viewModel.permissionManager)
                        .navigationTitle("欢迎")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .onAppear {
            viewModel.permissionManager.checkPermissions()
        }
    }
}

#Preview {
    ContentView()
}
