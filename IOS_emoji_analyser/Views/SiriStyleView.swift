//
//  SiriStyleView.swift
//  IOS_emoji_analyser
//
//  Created by Gemini on 2025/12/19.
//

import SwiftUI

struct SiriStyleView: View {
    @ObservedObject var viewModel: EmotionViewModel
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // 1. 动态背景
            DynamicBackgroundView()
            
            // 2. 内容层
            VStack {
                // 顶部状态栏占位
                HStack {
                    Spacer()
                    if viewModel.isModelReady {
                        Label("AI 就绪", systemImage: "sparkles")
                            .font(.caption)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal)
                
                Spacer()
                
                // Emoji 展示区
                if !viewModel.currentEmoji.isEmpty {
                    Text(viewModel.currentEmoji)
                        .font(.system(size: 140))
                        .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
                        .scaleEffect(viewModel.isListening ? 1.1 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.currentEmoji)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // 文本展示区
                if !viewModel.cachedText.isEmpty || !viewModel.recognizedText.isEmpty {
                    VStack(spacing: 8) {
                        Text(viewModel.isListening ? viewModel.recognizedText : viewModel.cachedText)
                            .font(.title3)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        
                        if viewModel.confidence > 0 {
                            Text("置信度: \(Int(viewModel.confidence * 100))%")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                }
                
                Spacer()
                
                // Siri 风格球体 / 交互区
                ZStack {
                    SiriOrbView(isListening: viewModel.isListening)
                        .frame(height: 120)
                        .onTapGesture {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            
                            withAnimation(.spring()) {
                                if viewModel.isListening {
                                    viewModel.stopListening()
                                } else {
                                    viewModel.startListening()
                                }
                            }
                        }
                    
                    VStack {
                        Spacer()
                        Text(viewModel.isListening ? "点击停止" : "点击开始")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.top, 140)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - 动态背景
struct DynamicBackgroundView: View {
    @State private var startAnimation: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            GeometryReader { proxy in
                let size = proxy.size
                
                // 蓝色光斑
                Circle()
                    .fill(Color.blue)
                    .frame(width: size.width * 0.8, height: size.width * 0.8)
                    .blur(radius: 60)
                    .offset(x: startAnimation ? -size.width * 0.3 : size.width * 0.3,
                            y: startAnimation ? -size.height * 0.2 : size.height * 0.1)
                
                // 紫色光斑
                Circle()
                    .fill(Color.purple)
                    .frame(width: size.width * 0.7, height: size.width * 0.7)
                    .blur(radius: 60)
                    .offset(x: startAnimation ? size.width * 0.3 : -size.width * 0.3,
                            y: startAnimation ? size.height * 0.1 : -size.height * 0.2)
                
                // 青色光斑
                Circle()
                    .fill(Color.cyan)
                    .frame(width: size.width * 0.6, height: size.width * 0.6)
                    .blur(radius: 50)
                    .offset(x: startAnimation ? -size.width * 0.1 : size.width * 0.2,
                            y: startAnimation ? size.height * 0.3 : size.height * 0.1)
            }
            .opacity(0.6)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                startAnimation.toggle()
            }
        }
    }
}

// MARK: - Siri 风格球体
struct SiriOrbView: View {
    var isListening: Bool
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // 外部光晕
            ForEach(0..<3) { i in
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.blue, .purple, .cyan, .blue]),
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 80 + CGFloat(i * 20), height: 80 + CGFloat(i * 20))
                    .rotationEffect(.degrees(isListening ? rotation * (Double(i) + 1) : 0))
                    .opacity(isListening ? 0.5 : 0.1)
                    .scaleEffect(isListening ? scale : 1.0)
            }
            
            // 核心球体
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [.white, .cyan, .blue, .purple]),
                        center: .center,
                        startRadius: 5,
                        endRadius: 60
                    )
                )
                .frame(width: 80, height: 80)
                .shadow(color: .blue, radius: 20, x: 0, y: 0)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                )
                .scaleEffect(isListening ? 1.1 : 1.0)
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                scale = 1.2
            }
        }
    }
}
