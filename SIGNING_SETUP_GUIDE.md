# 🔐 代码签名配置指南

## 问题描述
错误信息：`Signing for "IOS_emoji_analyser" requires a development team. Select a development team in the Signing & Capabilities editor.`

## ✅ 已完成的自动修复
已经在项目配置文件中添加了 `DEVELOPMENT_TEAM` 字段，现在您需要在 Xcode 中完成最后的配置。

---

## 📝 在 Xcode 中配置签名（3个步骤）

### 方案 1：使用个人开发者账号（推荐，免费）

#### 步骤 1：打开 Xcode 并添加 Apple ID
1. 打开 **Xcode**
2. 点击菜单栏 **Xcode** → **Settings...** (或按 `⌘,`)
3. 选择 **Accounts** 标签
4. 点击左下角的 **+** 按钮
5. 选择 **Apple ID**
6. 输入您的 Apple ID 和密码登录
7. 登录成功后会显示 **Personal Team**

#### 步骤 2：配置项目签名
1. 在 Xcode 左侧项目导航器中，点击最顶部的 **IOS_emoji_analyser** 项目（蓝色图标）
2. 在中间区域选择 **TARGETS** → **IOS_emoji_analyser**
3. 选择 **Signing & Capabilities** 标签
4. 确保 **Automatically manage signing** 已勾选 ✅
5. 在 **Team** 下拉菜单中选择您的 **Personal Team** (您的 Apple ID)
6. **Bundle Identifier** 会自动生成（如果冲突，可以改成 `com.yourname.IOS-emoji-analyser`）

#### 步骤 3：重新构建
1. 按 `⇧⌘K` (Shift + Command + K) 清理构建
2. 按 `⌘B` (Command + B) 重新构建
3. 按 `⌘R` (Command + R) 运行应用

---

### 方案 2：仅在模拟器上运行（无需签名）

如果您只想在模拟器上测试，可以跳过真机签名：

#### 步骤：
1. 在 Xcode 顶部工具栏，点击设备选择器（Run 按钮旁边）
2. 选择任意 **iOS Simulator**（例如：iPhone 15 Pro）
3. 按 `⌘R` 运行

**注意：** 模拟器上无法测试真实的麦克风功能，但可以使用 UI 测试按钮。

---

## 🚨 常见问题

### Q1: 没有 Apple ID 怎么办？
**A:** 免费注册一个！访问 https://appleid.apple.com/ 创建 Apple ID，然后按照方案 1 的步骤操作。

### Q2: Team 下拉菜单是空的？
**A:** 
1. 确保您已经在 Xcode → Settings → Accounts 中添加了 Apple ID
2. 点击 Team 下拉菜单旁边的 "Add an Account..." 按钮
3. 如果还是不行，重启 Xcode

### Q3: Bundle Identifier 冲突？
**A:** 修改 Bundle Identifier 为唯一值：
- 原值：`x.IOS-emoji-analyser`
- 改为：`com.yourname.IOSEmojiAnalyser` (用您的名字替换 yourname)

### Q4: 想在真机上测试？
**A:** 
1. 按照方案 1 配置好签名
2. 用 USB 线连接 iPhone 到 Mac
3. 在设备选择器中选择您的 iPhone
4. 首次运行时，需要在 iPhone 上信任开发者：
   - 设置 → 通用 → VPN与设备管理 → 开发者App → 信任

---

## 🎯 快速验证

配置完成后，运行以下检查：

### ✅ 签名配置成功的标志：
- Signing & Capabilities 标签页显示绿色的 ✓ 
- Team 字段显示您的团队名称
- Bundle Identifier 下方没有错误提示
- 构建时不再出现签名错误

### ✅ 应用运行成功的标志：
- 模拟器/真机上启动应用
- 看到权限请求界面
- 授予权限后看到主界面
- Emoji 显示正常

---

## 💡 提示

- **开发测试**：使用个人免费账号即可，无需付费
- **发布到 App Store**：需要加入 Apple Developer Program ($99/年)
- **真机调试**：个人账号每个设备需要重新信任，且证书有效期 7 天

---

## 📞 需要帮助？

如果按照上述步骤操作后仍然无法构建，请检查：
1. Xcode 版本是否是最新的
2. macOS 版本是否满足要求
3. 项目文件是否完整
4. 尝试重启 Xcode 和 Mac

---

**祝编码愉快！🚀**
