#!/bin/bash

# 冰阅 · 应用构建脚本
# 此脚本用于构建Android APK文件

set -e

echo "========================================"
echo "  冰阅 · APP构建开始"
echo "========================================"
echo ""

# 检查环境
echo "✓ 检查环境要求..."

if ! command -v cordova &> /dev/null; then
    echo "✗ 未找到Cordova，请先全局安装: npm install -g cordova"
    exit 1
fi

if ! command -v gradle &> /dev/null; then
    echo "✗ 未找到Gradle"
    echo "  请访问: https://gradle.org/install/"
    exit 1
fi

if [ -z "$ANDROID_HOME" ]; then
    echo "✗ 未设置ANDROID_HOME环境变量"
    echo "  请先安装Android SDK并设置ANDROID_HOME"
    exit 1
fi

echo "✓ Cordova版本: $(cordova --version)"
echo "✓ Node版本: $(node --version)"
echo "✓ npm版本: $(npm --version)"
echo ""

# 切到项目目录
cd "$(dirname "$0")"

# 安装项目依赖
echo "📦 安装项目依赖..."
npm install

# 检查是否已添加Android平台
if [ ! -d "platforms/android" ]; then
    echo "➕ 添加Android平台..."
    cordova platform add android@latest
else
    echo "✓ Android平台已存在"
fi

# 构建Release版本
echo "" 
echo "🔨 构建APK文件..."
cordova build android --release

echo ""
echo "========================================"
echo "  构建完成!"
echo "========================================"
echo ""

# 输出APK位置
APK_DIR="platforms/android/app/build/outputs/apk/release"
if [ -f "$APK_DIR/app-release.apk" ]; then
    echo "✓ 签名APK文件: $APK_DIR/app-release.apk"
    echo "  文件大小: $(du -h "$APK_DIR/app-release.apk" | cut -f1)"
elif [ -f "$APK_DIR/app-release-unsigned.apk" ]; then
    echo "⚠ 生成了未签名APK: $APK_DIR/app-release-unsigned.apk"
    echo ""
    echo "需要签名才能发布。使用以下命令:"
    echo "  jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 \ "
    echo "    -keystore my-release-key.jks \ "
    echo "    app-release-unsigned.apk alias_name"
fi
