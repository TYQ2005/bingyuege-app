# 冰阅 APP v1.0.0 发布命令速查

## 🚀 最快开始（一键发布）

```bash
chmod +x quick-publish.sh
./quick-publish.sh
```

## 📋 完整发布流程（分步）

### 步骤 1: 本地验证
```bash
cd /path/to/bingyuege-app
git status          # 检查 Git 状态
npm --version       # 检查 npm（可选）
```

### 步骤 2: 选择构建方式

#### 方式 A: 本地构建（需要 Java + Android SDK）
```bash
npm install
cordova platform add android@latest
npm run build
# 或
cordova build android --release
```

#### 方式 B: Docker 构建（推荐，无需本地SDK）
```bash
chmod +x docker-build.sh
./docker-build.sh
```

#### 方式 C: GitHub Actions 构建（云端自动化）
```bash
git push origin v1.0.0
# 访问: https://github.com/TYQ2005/bingyuege-app/actions
# 等待构建完成
```

### 步骤 3: 创建 GitHub Release

```bash
# 设置 GitHub Token
export GITHUB_TOKEN=ghp_your_token_here

# 创建 Release 并上传 APK
chmod +x github-release.sh
./github-release.sh v1.0.0
```

## 🔧 环境配置

### 获取 GitHub Token
1. 访问: https://github.com/settings/tokens/new
2. 选择权限: `repo`
3. 点击 "Generate token"
4. 复制令牌

### 设置环境变量
```bash
export GITHUB_TOKEN=your_token_here
```

## 📁 重要文件位置

| 类型 | 位置 |
|------|------|
| Release APK | `platforms/android/app/build/outputs/apk/release/app-release.apk` |
| 无签名 APK | `platforms/android/app/build/outputs/apk/release/app-release-unsigned.apk` |
| Debug APK | `platforms/android/app/build/outputs/apk/debug/app-debug.apk` |

## 📝 发布脚本说明

| 脚本 | 用途 | 用法 |
|------|------|------|
| `quick-publish.sh` | 一键快速发布 | `./quick-publish.sh` |
| `publish-release.sh` | 完整发布工作流 | `./publish-release.sh v1.0.0` |
| `docker-build.sh` | Docker 容器构建 | `./docker-build.sh` |
| `github-release.sh` | GitHub Release 管理 | `./github-release.sh v1.0.0` |

## ✅ 验证发布

### 检查构建输出
```bash
find platforms/android -name "*.apk" -type f -exec ls -lh {} \;
```

### 验证 APK 信息
```bash
aapt dump badging app-release.apk
# 或
apksigner verify -v app-release.apk
```

### 在设备上测试
```bash
adb install app-release.apk
adb shell am start -n com.bingyuege.app/.MainActivity
```

## 🌐 GitHub Releases 地址

- 标签发布: https://github.com/TYQ2005/bingyuege-app/releases/tag/v1.0.0
- 所有发布: https://github.com/TYQ2005/bingyuege-app/releases
- Actions: https://github.com/TYQ2005/bingyuege-app/actions

## 🆘 常见问题

### ❓ 如何重新发布？
```bash
# 删除已存在的 Release
git tag -d v1.0.0
git push origin :v1.0.0

# 重新创建和发布
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

### ❓ APK 太大怎么办？
- 检查是否包含不必要的资源
- 启用 ProGuard/R8 混淆
- 压缩图像资源

### ❓ 签署失败？
```bash
# 重新生成密钥
keytool -genkey -v -keystore release.jks \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias app
```

## 📞 获取帮助

- 📖 详细指南: [RELEASE_GUIDE.md](RELEASE_GUIDE.md)
- 📱 APK 发布: [PUBLISH_APK.md](PUBLISH_APK.md)
- 🛠️ 构建指南: [BUILD_GUIDE.md](BUILD_GUIDE.md)
- 🐛 报告问题: https://github.com/TYQ2005/bingyuege-app/issues

---

**最后更新**: 2026-02-13  
**维护**: 冰阅开发团队
