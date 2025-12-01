#!/bin/bash

# 🚀 Xcode 文件添加快速指南
# 这个脚本会列出所有需要添加到 Xcode 的文件

echo "================================================"
echo "📋 需要添加到 Xcode 项目的文件清单"
echo "================================================"
echo ""
echo "请按照以下步骤操作："
echo ""
echo "1️⃣  打开 Xcode 项目"
echo "   open IOS_emoji_analyser.xcodeproj"
echo ""
echo "2️⃣  打开 Finder 到项目目录"
echo "   open IOS_emoji_analyser/"
echo ""
echo "3️⃣  需要添加的文件夹："
echo "   ✅ Models/"
echo "   ✅ Views/"
echo "   ✅ ViewModels/"
echo "   ✅ Utilities/"
echo "   ✅ Info.plist"
echo ""
echo "4️⃣  拖拽方法："
echo "   - 在 Xcode 左侧选中 'IOS_emoji_analyser' 文件夹"
echo "   - 从 Finder 拖拽上述文件夹到 Xcode"
echo "   - 勾选 'Copy items if needed'"
echo "   - 勾选 'Create groups'"
echo "   - 勾选 'Add to targets: IOS_emoji_analyser'"
echo "   - 点击 Finish"
echo ""
echo "================================================"
echo "📁 文件详情"
echo "================================================"
echo ""

# 列出所有需要添加的文件
echo "Models/ 文件夹 (2个文件):"
find IOS_emoji_analyser/Models -name "*.swift" 2>/dev/null | while read file; do
    echo "  ✅ $(basename "$file")"
done

echo ""
echo "Views/ 文件夹 (3个文件):"
find IOS_emoji_analyser/Views -name "*.swift" 2>/dev/null | while read file; do
    echo "  ✅ $(basename "$file")"
done

echo ""
echo "ViewModels/ 文件夹 (1个文件):"
find IOS_emoji_analyser/ViewModels -name "*.swift" 2>/dev/null | while read file; do
    echo "  ✅ $(basename "$file")"
done

echo ""
echo "Utilities/ 文件夹 (2个文件):"
find IOS_emoji_analyser/Utilities -name "*.swift" 2>/dev/null | while read file; do
    echo "  ✅ $(basename "$file")"
done

echo ""
echo "配置文件:"
echo "  ✅ Info.plist"

echo ""
echo "================================================"
echo "⚙️  添加完成后的操作"
echo "================================================"
echo ""
echo "1. 在 Xcode 中按 ⌘B 构建项目"
echo "2. 检查是否有编译错误"
echo "3. 配置权限描述（见下文）"
echo "4. 按 ⌘R 运行项目"
echo ""
echo "================================================"
echo "🔐 权限配置（重要！）"
echo "================================================"
echo ""
echo "在 Xcode 中："
echo "1. 点击项目名称（蓝色图标）"
echo "2. 选择 Target: IOS_emoji_analyser"
echo "3. 选择 Info 标签页"
echo "4. 添加以下权限："
echo ""
echo "   Privacy - Microphone Usage Description"
echo "   我们需要访问您的麦克风来实时录制语音，以便进行情绪分析"
echo ""
echo "   Privacy - Speech Recognition Usage Description"
echo "   我们需要使用语音识别功能将您的语音转换为文字，以便分析情绪"
echo ""
echo "================================================"
echo "✅ 完成！"
echo "================================================"
echo ""
echo "详细说明请查看: HOW_TO_ADD_FILES_TO_XCODE.md"
echo ""
