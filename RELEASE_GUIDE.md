# 冰阅 APP v1.0.0 发布指南

## 🎯 发布概述

本指南说明如何构建和发布冰阅 APP v1.0.0 的 Android APK 文件到 GitHub Releases。

## 📱 APK 发布方式

### 方式一：使用 GitHub Actions 自动构建（推荐）

GitHub 仓库已配置自动化 CI/CD 流程，可以自动构建和发布 APK。

**步骤：**

1. **确保标签已推送到 GitHub**
   ```bash
   git push origin v1.0.0
   ```
   这会自动触发 GitHub Actions 工作流

2. **监控构建进度**
   - 访问：https://github.com/TYQ2005/bingyuege-app/actions
   - 查找 "v1.0.0" 的构建任务
   - 等待构建完成（通常需要 5-15 分钟）

3. **检查 GitHub Releases**
   - 访问：https://github.com/TYQ2005/bingyuege-app/releases/tag/v1.0.0
   - 验证 APK 文件已上传
   - 下载 APK 文件

4. **在 Android 设备上安装**
   ```bash
   adb install platforms/android/app/build/outputs/apk/release/app-release.apk
   ```

### 方式二：本地构建

如果 GitHub Actions 构建失败或需要本地控制，可以本地构建：

**前置要求：**
- Node.js 14+
- Java JDK 11+
- Android SDK (API 23+)
- Cordova CLI

**构建步骤：**

1. **安装依赖**
   ```bash
   npm install
   cordova platform add android@latest
   ```

2. **构建 Release APK**
   ```bash
   cordova build android --release
   ```

3. **APK 输出位置**
   - 无签名：`platforms/android/app/build/outputs/apk/release/app-release-unsigned.apk`
   - 已签名：需要手动签署

4. **签署 APK（可选但推荐）**
   
   **生成签名密钥**（首次）：
   ```bash
   keytool -genkey -v -keystore bingyuege-release-key.jks \
       -keyalg RSA -keysize 2048 -validity 10000 \
       -alias bingyuege \
       -storepass password123 \
       -keypass password123
   ```

   **使用密钥签署 APK**：
   ```bash
   jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 \
       -keystore bingyuege-release-key.jks \
       -storepass password123 \
       platforms/android/app/build/outputs/apk/release/app-release-unsigned.apk \
       bingyuege
   
   # 优化 APK 大小
   zipalign -v 4 platforms/android/app/build/outputs/apk/release/app-release-unsigned.apk \
       platforms/android/app/build/outputs/apk/release/app-release-signed.apk
   ```

5. **使用自动化发布脚本**
   ```bash
   chmod +x release.sh
   ./release.sh
   ```

## 📦 发布到 GitHub Releases

### 使用 GitHub CLI（gh）

1. **创建 Release**
   ```bash
   gh release create v1.0.0 \
       platforms/android/app/build/outputs/apk/release/app-release.apk \
       --title "冰阅 v1.0.0" \
       --notes "Release notes here"
   ```

### 手动创建 Release

1. 访问 https://github.com/TYQ2005/bingyuege-app/releases
2. 点击 "Draft a new release"
3. 选择标签 "v1.0.0"
4. 填写发布标题和说明
5. 上传 APK 文件
6. 发布 Release

## ✨ v1.0.0 主要功能

- ✅ 支持 JSON/XML/文本/URL 四种格式书源导入
- ✅ 完整的书籍管理和阅读功能
- ✅ 夜间/白天主题切换
- ✅ 阅读进度自动保存
- ✅ 章节导航和目录快速定位
- ✅ 书架管理和同步

## 🔍 验证发布

### 检查 APK 信息

```bash
# 使用 aapt 查看 APK 信息
aapt dump badging app-release.apk

# 或使用 apksigner 验证签名
apksigner verify -v app-release.apk
```

### 在设备上测试

1. 连接 Android 设备
2. 允许 ADB 调试
3. 安装 APK：
   ```bash
   adb install -r app-release.apk
   ```
4. 启动应用并测试所有功能

## 📋 检查清单

- [ ] 所有代码已提交到 GitHub
- [ ] v1.0.0 标签已创建并推送
- [ ] GitHub Actions 构建成功
- [ ] APK 文件已上传至 GitHub Releases
- [ ] APK 文件大小合理（通常 10-30MB）
- [ ] APK 已在真实设备上测试
- [ ] README 已更新为最新版本说明
- [ ] 更新日志（CHANGELOG.md）已更新

## 🤝 常见问题

### Q: GitHub Actions 构建失败？
A: 检查以下内容：
- package.json 中的依赖配置
- Cordova 平台支持
- Android SDK 版本兼容性
- 网络连接质量

### Q: APK 签署失败？
A: 确保：
- keytool 和 jarsigner 已安装
- 密钥库文件路径正确
- 密码正确
- APK 路径正确

### Q: 如何回滚发布？
A: 在 GitHub Releases 页面点击发布的 Release，然后点击 "Delete"
然后删除对应的标签：
```bash
git tag -d v1.0.0
git push origin :v1.0.0
```

## 📞 支持

如有问题，请提交 Issue 或 PR 到：
https://github.com/TYQ2005/bingyuege-app/issues

## 📜 许可证

MIT License
