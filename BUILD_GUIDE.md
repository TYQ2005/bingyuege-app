# 冰阅 · APP 构建与发布指南

## 📋 目录

1. [环境要求](#环境要求)
2. [快速开始](#快速开始)
3. [详细步骤](#详细步骤)
4. [发布流程](#发布流程)
5. [常见问题](#常见问题)

---

## 环境要求

### 必需软件

| 软件 | 版本 | 说明 |
|------|------|------|
| Node.js | ≥16.0 | JavaScript运行环境 |
| npm | ≥8.0 | 包管理器 |
| Java JDK | ≥11 | Android构建依赖 |
| Android SDK | ≥API 30 | Android开发工具包 |
| Gradle | ≥7.5 | 自动包含在Android SDK |
| Cordova CLI | ≥12.0 | 移动应用框架 |

### 环境变量配置

#### Windows

```batch
REM 设置Java Home
set JAVA_HOME=C:\Program Files\Java\jdk-11
set PATH=%JAVA_HOME%\bin;%PATH%

REM 设置Android Home
set ANDROID_HOME=C:\Android\Sdk
set PATH=%ANDROID_HOME%\tools;%ANDROID_HOME%\platform-tools;%PATH%
```

#### macOS/Linux

```bash
# 添加到 ~/.bashrc 或 ~/.zshrc

export JAVA_HOME=$(/usr/libexec/java_home)
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH
```

---

## 快速开始

### 方法一：使用自动化脚本（推荐）

#### Linux/macOS

```bash
# 赋予执行权限
chmod +x build.sh

# 执行构建
./build.sh
```

#### Windows

```batch
REM 直接运行
build.bat
```

### 方法二：手动构建

```bash
# 1. 安装Cordova CLI
npm install -g cordova

# 2. 进入项目目录
cd bingyuege-app

# 3. 安装项目依赖
npm install

# 4. 添加Android平台
cordova platform add android

# 5. 构建APK
cordova build android --release
```

---

## 详细步骤

### 1. 安装开发环境

#### Step 1.1: 安装Java JDK

**Windows:**
- 访问 https://www.oracle.com/java/technologies/downloads/
- 下载 Java 11 或更高版本
- 运行安装程序，记住安装路径

**macOS:**
```bash
brew install openjdk@11
sudo ln -sfn $(brew --prefix openjdk@11)/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk
```

**Linux:**
```bash
sudo apt-get install openjdk-11-jdk
```

#### Step 1.2: 安装Android SDK

**推荐方法：使用Android Studio**

1. 下载 https://developer.android.com/studio
2. 安装Android Studio
3. 打开SDK Manager
4. 安装以下组件：
   - Android SDK Platform 30及以上
   - Android SDK Build-Tools
   - Android Emulator（可选）

**命令行方法：** 使用 Android SDK Command-line Tools

```bash
# macOS/Linux
mkdir -p ~/Android/Sdk
cd ~/Android/Sdk
wget https://dl.google.com/android/repository/commandlinetools-linux-*.zip
unzip commandlinetools-linux-*.zip

# 安装必要的SDK
./cmdline-tools/bin/sdkmanager "platforms;android-33" "build-tools;33.0.0"
```

#### Step 1.3: 安装Node.js和npm

访问 https://nodejs.org/ 下载LTS版本

验证安装：
```bash
node --version
npm --version
```

#### Step 1.4: 安装Cordova

```bash
npm install -g cordova

# 验证
cordova --version
```

### 2. 项目编译

```bash
# 进入项目目录
cd bingyuege-app

# 安装依赖
npm install

# 添加Android平台（首次）
cordova platform add android@latest

# 编译应用
cordova build android --release
```

### 3. 生成的APK位置

构建完成后，APK文件位于：

```
platforms/android/app/build/outputs/apk/release/
├── app-release.apk           # 已签名的APK
└── app-release-unsigned.apk  # 未签名的APK
```

---

## 发布流程

### 步骤1: 创建密钥库（仅首次需要）

密钥库用于签名APK，确保应用的真实性。

#### 生成密钥

```bash
# Linux/macOS
keytool -genkey -v -keystore bingyuege-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias bingyuege

# Windows
keytool -genkey -v -keystore bingyuege-release-key.jks ^
  -keyalg RSA -keysize 2048 -validity 10000 ^
  -alias bingyuege
```

按照提示输入信息：
```
密钥库密码: (设置密码，如: MyPassword123!)
密钥密码:   (通常与密钥库密码相同)
名字:      冰阅开发团队
组织单位:   Development
组织名:    冰阅阁
城市:      Beijing
省份:      Beijing
国家代码:   CN
```

### 步骤2: 签名APK

```bash
# Linux/macOS
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 \
  -keystore bingyuege-release-key.jks \
  platforms/android/app/build/outputs/apk/release/app-release-unsigned.apk \
  bingyuege

# Windows
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 ^
  -keystore bingyuege-release-key.jks ^
  platforms\android\app\build\outputs\apk\release\app-release-unsigned.apk ^
  bingyuege
```

### 步骤3: 优化APK

```bash
# Linux/macOS
zipalign -v 4 \
  platforms/android/app/build/outputs/apk/release/app-release-unsigned.apk \
  bingyuege-app-release.apk

# Windows
zipalign -v 4 ^
  platforms\android\app\build\outputs\apk\release\app-release-unsigned.apk ^
  bingyuege-app-release.apk
```

### 步骤4: 上传到GitHub Releases

```bash
# 创建Release标签
git tag -a v1.0.0 -m "冰阅 v1.0.0 - 首个APP版本发布"

# 推送标签到GitHub
git push origin v1.0.0

# 或使用GitHub CLI
gh release create v1.0.0 bingyuege-app-release.apk \
  --title "冰阅 v1.0.0" \
  --notes "✨ 首个APP版本\n\n## 功能特性\n- 支持JSON/XML/文本/URL书源导入\n- 完整的书籍阅读功能"
```

### 步骤5: 发布到Google Play Store

1. 注册Google Play开发者账户：https://play.google.com/console
2. 创建新应用
3. 填写应用信息：
   - 应用名称：冰阅
   - 简述：多功能阅读APP
   - 完整描述：见README.md
   - 类别：书籍与参考资料
4. 上传APK文件
5. 提交审核

---

## 常见问题

### Q1: 编译错误 "Unable to locate Android SDK"

**原因：** 未正确设置ANDROID_HOME

**解决：**
```bash
# 检查环境变量
echo $ANDROID_HOME  # Linux/macOS
echo %ANDROID_HOME%  # Windows

# 设置正确的路径
export ANDROID_HOME=$HOME/Android/Sdk  # Linux/macOS
set ANDROID_HOME=C:\Android\Sdk  # Windows
```

### Q2: "cordova: command not found"

**原因：** Cordova未全局安装

**解决：**
```bash
npm install -g cordova
```

### Q3: APK文件很大（>50MB）

**原因：** 包含了不必要的资源和调试信息

**解决：**
```bash
# 构建优化版本
cordova build android --release -- --minSdkVersion=21

# 使用ProGuard混淆和优化
cordova build android --release -- --gradle
```

### Q4: 签名错误 "jarsigner: not found"

**原因：** jarsigner命令不在PATH中

**解决：**
```bash
# 使用完整路径
$JAVA_HOME/bin/jarsigner ...  # Linux/macOS
%JAVA_HOME%\bin\jarsigner ...  # Windows
```

### Q5: 构建超时

**原因：** 首次构建下载依赖耗时较长

**解决：**
```bash
# 增加超时时间
export GRADLE_OPTS="-Dorg.gradle.jvmargs=-Xmx1024m"
cordova build android --release
```

---

## 构建配置文件

### config.xml 主要配置

```xml
<widget id="com.bingyuege.app" version="1.0.0">
  <name>冰阅</name>
  <description>多功能阅读APP</description>
  <author email="dev@bingyuege.app">冰阅开发团队</author>
  <content src="index.html" />
  <access origin="*" />
  
  <platform name="android">
    <allow-intent href="market:*" />
    <preference name="SplashScreen" value="screen" />
    <preference name="SplashScreenDelay" value="3000" />
  </platform>
</widget>
```

### package.json 脚本配置

```json
{
  "scripts": {
    "build": "cordova build android --release",
    "run": "cordova run android",
    "clean": "cordova clean"
  }
}
```

---

## 发布检查清单

- [ ] 代码已提交到GitHub
- [ ] 版本号已更新（config.xml 和 package.json）
- [ ] 应用图标已设置（1024x1024及以上）
- [ ] 隐私政策已准备
- [ ] 更新日志已记录
- [ ] APK已签名和优化
- [ ] 在真机上测试完毕
- [ ] Release标签已创建
- [ ] GitHub Releases已发布

---

## 相关资源

- [Cordova官方文档](https://cordova.apache.org/docs/en/latest/)
- [Android开发者文档](https://developer.android.com/docs)
- [Google Play应用发布指南](https://support.google.com/googleplay/android-developer/answer/9859152)
- [APK签名指南](https://developer.android.com/studio/publish/app-signing)

---

## 支持和反馈

如有问题，请在GitHub Issues中提出：
https://github.com/TYQ2005/bingyuege-app/issues
