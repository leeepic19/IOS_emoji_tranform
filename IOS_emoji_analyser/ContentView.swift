//
//  ContentView.swift
//  IOS_emoji_analyser
//
//  Created by 李玉广 on 2025/12/1.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = EmotionViewModel()
    @State private var showDebugView: Bool = false
    @State private var useImmersiveUI: Bool = true
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.permissionManager.allPermissionsGranted {
                    if useImmersiveUI {
                        SiriStyleView(viewModel: viewModel)
                            .navigationBarHidden(true)
                            .overlay(
                                VStack {
                                    HStack {
                                        Spacer()
                                        // 切换回经典视图
                                        Button(action: { useImmersiveUI = false }) {
                                            Image(systemName: "rectangle.grid.1x2.fill")
                                                .font(.title2)
                                                .foregroundColor(.white.opacity(0.7))
                                                .padding(10)
                                                .background(.ultraThinMaterial)
                                                .clipShape(Circle())
                                        }
                                        
                                        // 设置按钮
                                        NavigationLink(destination: SettingsView()) {
                                            Image(systemName: "gear")
                                                .font(.title2)
                                                .foregroundColor(.white.opacity(0.7))
                                                .padding(10)
                                                .background(.ultraThinMaterial)
                                                .clipShape(Circle())
                                        }
                                    }
                                    .padding(.top, 50)
                                    .padding(.trailing, 20)
                                    Spacer()
                                }
                            )
                    } else {
                        // 主界面 - 权限已授予
                        EmojiDisplayView(viewModel: viewModel)
                            .navigationTitle("Emoji 情绪分析")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    HStack(spacing: 16) {
                                        Button(action: { useImmersiveUI = true }) {
                                            Image(systemName: "sparkles")
                                                .foregroundColor(.purple)
                                        }
                                        Button(action: { showDebugView = true }) {
                                            Image(systemName: "ant.fill")
                                                .foregroundColor(.orange)
                                        }
                                        NavigationLink(destination: SettingsView()) {
                                            Image(systemName: "gear")
                                        }
                                    }
                                }
                            }
                            .sheet(isPresented: $showDebugView) {
                                DebugTestView(viewModel: viewModel)
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

// MARK: - Siri Style View (Integrated)

enum BackgroundStyle: String, CaseIterable, Identifiable {
    case fluid = "流体"
    case inkLandscape = "山水"
    case waterRipple = "水面"
    
    var id: String { self.rawValue }
}

struct SiriStyleView: View {
    @ObservedObject var viewModel: EmotionViewModel
    @State private var currentBackground: BackgroundStyle = .fluid
    @State private var showBackgroundPicker = false
    
    // 交互状态
    @State private var touchLocation: CGPoint = .zero
    @State private var isTouching: Bool = false
    
    // Emoji 动画状态
    @State private var emojiFloating = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. 动态背景 (传入交互坐标)
                Group {
                    switch currentBackground {
                    case .fluid:
                        FluidBackgroundView(touchLocation: touchLocation, isTouching: isTouching, size: geometry.size)
                    case .inkLandscape:
                        InkLandscapeBackgroundView(touchLocation: touchLocation, size: geometry.size)
                    case .waterRipple:
                        WaterRippleBackgroundView(touchLocation: touchLocation, isTouching: isTouching, size: geometry.size)
                    }
                }
                .transition(.opacity.animation(.easeInOut(duration: 1.0)))
                
                // 1.5 交互层 (透明层专门接收手势，确保不被遮挡)
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                touchLocation = value.location
                                withAnimation(.interactiveSpring()) {
                                    isTouching = true
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeOut(duration: 0.5)) {
                                    isTouching = false
                                }
                            }
                    )
                
                // 2. 内容层
                VStack {
                    // 顶部状态栏
                    HStack {
                        // 背景切换按钮
                        Button(action: { withAnimation { showBackgroundPicker.toggle() } }) {
                            HStack(spacing: 6) {
                                Image(systemName: "paintpalette.fill")
                                Text(currentBackground.rawValue)
                            }
                            .font(.caption)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .foregroundColor(.white)
                        }
                        
                        if showBackgroundPicker {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(BackgroundStyle.allCases) { style in
                                        Button(action: {
                                            withAnimation {
                                                currentBackground = style
                                                showBackgroundPicker = false
                                            }
                                        }) {
                                            Text(style.rawValue)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(currentBackground == style ? Color.white : Color.black.opacity(0.3))
                                                .foregroundColor(currentBackground == style ? .black : .white)
                                                .cornerRadius(15)
                                        }
                                    }
                                }
                            }
                            .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                        
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
                    
                    // Emoji 展示区 (灵动版)
                    if !viewModel.currentEmoji.isEmpty {
                        ZStack {
                            // 光晕背景
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 180, height: 180)
                                .blur(radius: 30)
                                .scaleEffect(emojiFloating ? 1.1 : 0.9)
                                .opacity(emojiFloating ? 0.5 : 0.3)
                            
                            Text(viewModel.currentEmoji)
                                .font(.system(size: 140))
                                .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
                                // 呼吸缩放
                                .scaleEffect(viewModel.isListening ? 1.15 : (emojiFloating ? 1.05 : 0.95))
                                // 悬浮位移
                                .offset(y: emojiFloating ? -10 : 10)
                                // 触摸跟随 (简单的视差)
                                .rotation3DEffect(
                                    .degrees(isTouching ? Double(touchLocation.x - geometry.size.width/2) / 20 : 0),
                                    axis: (x: 0, y: 1, z: 0)
                                )
                                .rotation3DEffect(
                                    .degrees(isTouching ? Double(geometry.size.height/2 - touchLocation.y) / 20 : 0),
                                    axis: (x: 1, y: 0, z: 0)
                                )
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: emojiFloating)
                                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.currentEmoji)
                        }
                        .onAppear {
                            emojiFloating = true
                        }
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
}

// MARK: - 1. 流体背景 (交互版)
struct FluidBackgroundView: View {
    var touchLocation: CGPoint
    var isTouching: Bool
    var size: CGSize
    @State private var startAnimation: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // 蓝色光斑 (跟随触摸)
            Circle()
                .fill(Color.blue)
                .frame(width: size.width * 0.8, height: size.width * 0.8)
                .blur(radius: 60)
                .offset(x: startAnimation ? -size.width * 0.3 : size.width * 0.3,
                        y: startAnimation ? -size.height * 0.2 : size.height * 0.1)
                .offset(x: isTouching ? (touchLocation.x - size.width/2) * 0.2 : 0,
                        y: isTouching ? (touchLocation.y - size.height/2) * 0.2 : 0)
            
            // 紫色光斑 (反向移动)
            Circle()
                .fill(Color.purple)
                .frame(width: size.width * 0.7, height: size.width * 0.7)
                .blur(radius: 60)
                .offset(x: startAnimation ? size.width * 0.3 : -size.width * 0.3,
                        y: startAnimation ? size.height * 0.1 : -size.height * 0.2)
                .offset(x: isTouching ? -(touchLocation.x - size.width/2) * 0.15 : 0,
                        y: isTouching ? -(touchLocation.y - size.height/2) * 0.15 : 0)
            
            // 青色光斑
            Circle()
                .fill(Color.cyan)
                .frame(width: size.width * 0.6, height: size.width * 0.6)
                .blur(radius: 50)
                .offset(x: startAnimation ? -size.width * 0.1 : size.width * 0.2,
                        y: startAnimation ? size.height * 0.3 : size.height * 0.1)
                .scaleEffect(isTouching ? 1.1 : 1.0)
        }
        .animation(.interactiveSpring(), value: touchLocation)
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                startAnimation.toggle()
            }
        }
    }
}

// MARK: - 2. 山水中国风背景 (增强版 + 交互)
struct InkLandscapeBackgroundView: View {
    var touchLocation: CGPoint
    var size: CGSize
    @State private var cloudOffset: CGFloat = 0
    @State private var birdOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // 1. 纸张底色 (带纹理感)
            ZStack {
                LinearGradient(gradient: Gradient(colors: [
                    Color(red: 0.96, green: 0.95, blue: 0.92), // 米白
                    Color(red: 0.88, green: 0.87, blue: 0.83)  // 浅灰黄
                ]), startPoint: .top, endPoint: .bottom)
                
                // 噪点纹理模拟宣纸
                Color.white.opacity(0.3)
                    .blendMode(.overlay)
            }
            .ignoresSafeArea()
            
            // 2. 太阳 (红印)
            Circle()
                .fill(LinearGradient(colors: [.red.opacity(0.8), .red.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                .frame(width: 60, height: 60)
                .blur(radius: 1)
                .offset(x: 100, y: -250)
                .shadow(color: .red.opacity(0.3), radius: 10)
                // 视差
                .offset(x: (touchLocation.x - size.width/2) * 0.02,
                        y: (touchLocation.y - size.height/2) * 0.02)
            
            // 3. 飞鸟 (动态)
            HStack(spacing: -10) {
                ForEach(0..<3) { i in
                    Image(systemName: "chevron.up") // 用 chevron 模拟飞鸟翅膀
                        .font(.system(size: 10 + CGFloat(i)*2, weight: .bold))
                        .foregroundColor(.black.opacity(0.6))
                        .rotationEffect(.degrees(120))
                        .offset(y: CGFloat(i) * 5)
                }
            }
            .offset(x: birdOffset - 200, y: -180)
            .opacity(0.7)
            
            // 4. 远山 (淡墨)
            MountainShape(amplitude: 30, frequency: 1.5)
                .fill(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.05)]), startPoint: .top, endPoint: .bottom))
                .frame(height: size.height * 0.5)
                .offset(y: size.height * 0.1)
                .scaleEffect(x: 1.2, y: 1.0)
                // 视差
                .offset(x: (touchLocation.x - size.width/2) * 0.03)
            
            // 5. 中山 (中墨)
            MountainShape(amplitude: 50, frequency: 2.0)
                .fill(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.2)]), startPoint: .top, endPoint: .bottom))
                .frame(height: size.height * 0.4)
                .offset(y: size.height * 0.25)
                // 视差
                .offset(x: (touchLocation.x - size.width/2) * 0.06)
            
            // 6. 云雾 (层间)
            Circle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 200, height: 100)
                .blur(radius: 30)
                .offset(x: -100, y: 100)
            
            // 7. 近山 (浓墨)
            MountainShape(amplitude: 80, frequency: 1.2)
                .fill(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black.opacity(0.5)]), startPoint: .top, endPoint: .bottom))
                .frame(height: size.height * 0.35)
                .offset(y: size.height * 0.4)
                // 视差
                .offset(x: (touchLocation.x - size.width/2) * 0.1)
            
            // 8. 前景云雾
            Image(systemName: "cloud.fill")
                .font(.system(size: 120))
                .foregroundColor(.white.opacity(0.5))
                .offset(x: cloudOffset, y: 200)
                .blur(radius: 15)
        }
        .animation(.interactiveSpring(), value: touchLocation)
        .onAppear {
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                cloudOffset = 300
            }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                birdOffset = 400
            }
        }
    }
}

// 简单的山形 Shape
struct MountainShape: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: 0, y: height * 0.5))
        
        for x in stride(from: 0, to: width, by: 5) {
            let relativeX = x / width
            let sine = sin(relativeX * .pi * frequency)
            // 使用确定性的噪声替代随机数，防止重绘时抖动
            let noise = sin(relativeX * 50) * 2 + cos(relativeX * 30) * 2
            let y = height * 0.5 - (sine * amplitude) + noise
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height * 0.5))
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        return path
    }
}

// MARK: - 3. 水面灵动风背景 (交互版)
struct WaterRippleBackgroundView: View {
    var touchLocation: CGPoint
    var isTouching: Bool
    var size: CGSize
    @State private var phase: CGFloat = 0
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(red: 0.0, green: 0.15, blue: 0.3), Color(red: 0.0, green: 0.4, blue: 0.6)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            // 自动波纹
            ForEach(0..<5) { i in
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 2)
                    .scaleEffect(1 + CGFloat(i) * 0.5 + phase)
                    .opacity(1.0 - phase * 0.5)
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: false).delay(Double(i) * 0.8), value: phase)
            }
            
            // 触摸产生的波纹 (模拟)
            if isTouching {
                Circle()
                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                    .frame(width: 100, height: 100)
                    .position(touchLocation)
                    .scaleEffect(phase * 2)
                    .opacity(1.0 - phase)
                    .blur(radius: 2)
            }
            
            // 水光潋滟 (粒子)
            ForEach(0..<8) { i in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: CGFloat.random(in: 30...100), height: CGFloat.random(in: 30...100))
                    .position(x: CGFloat.random(in: 0...size.width), y: CGFloat.random(in: 0...size.height))
                    .blur(radius: 15)
                    // 简单的避让效果
                    .offset(x: isTouching ? (CGFloat.random(in: 0...size.width) - touchLocation.x) * 0.1 : 0,
                            y: isTouching ? (CGFloat.random(in: 0...size.height) - touchLocation.y) * 0.1 : 0)
                    .animation(.easeInOut(duration: Double.random(in: 3...6)).repeatForever(autoreverses: true), value: phase)
            }
        }
        .animation(.interactiveSpring(), value: touchLocation)
        .onAppear {
            phase = 1.0
        }
    }
}

// MARK: - Siri 风格球体 (增强版)
struct SiriOrbView: View {
    var isListening: Bool
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var innerRotation: Double = 0
    
    var body: some View {
        ZStack {
            // 1. 外部光晕 (多层旋转)
            ForEach(0..<3) { i in
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.0), .purple.opacity(0.5), .cyan.opacity(0.5), .blue.opacity(0.0)]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 80 + CGFloat(i * 25), height: 80 + CGFloat(i * 25))
                    .rotationEffect(.degrees(isListening ? rotation * (Double(i) * 0.5 + 1) : 0))
                    .opacity(isListening ? 0.6 : 0.1)
                    .scaleEffect(isListening ? scale : 1.0)
                    .blendMode(.plusLighter) // 增加发光感
            }
            
            // 2. 核心球体 (流光溢彩)
            ZStack {
                // 核心底色
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [.white, .cyan, .blue]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 80, height: 80)
                    .blur(radius: 5)
                
                // 内部流光
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red]),
                            center: .center
                        )
                    )
                    .frame(width: 76, height: 76)
                    .mask(Circle().blur(radius: 10))
                    .rotationEffect(.degrees(innerRotation))
                    .opacity(0.4)
                    .blendMode(.overlay)
                
                // 高光反射
                Circle()
                    .stroke(Color.white.opacity(0.8), lineWidth: 2)
                    .frame(width: 78, height: 78)
                    .blur(radius: 1)
            }
            .shadow(color: .blue.opacity(0.6), radius: 30, x: 0, y: 0)
            .scaleEffect(isListening ? 1.1 : 1.0)
        }
        .onAppear {
            // 外部旋转动画
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            // 内部流光动画
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                innerRotation = 360
            }
            // 呼吸动画
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                scale = 1.15
            }
        }
    }
}
