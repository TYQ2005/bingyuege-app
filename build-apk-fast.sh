#!/bin/bash

# 冰阅 APP 完整 APK 生成工具
# 使用预编译的 Gradle 和 Cordova 生成 Release APK
# 不依赖 npm install

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
output_dir="$PROJECT_DIR/apk_output"
mkdir -p "$output_dir"

echo ""
echo "🚀 冰阅 APP APK 快速生成工具"
echo "================================"
echo ""

# 检查必要工具
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ 需要安装: $1"
        return 1
    fi
    return 0
}

echo "检查工具..."
tools_ok=true

if ! check_tool "java"; then
    echo "  → 需要 Java JDK 11+"
    tools_ok=false
fi

if ! check_tool "gradle"; then
    echo "  ⚠️  Gradle 未安装"
    echo "  → 尝试使用本地 gradlew..."
fi

if [ ! -d "$ANDROID_HOME" ]; then
    if [ -d "$HOME/Android/Sdk" ]; then
        export ANDROID_HOME="$HOME/Android/Sdk"
        echo "✅ 自动设置 ANDROID_HOME"
    else
        echo "❌ 需要设置 ANDROID_HOME 或安装 Android SDK"
        tools_ok=false
    fi
fi

if [ "$tools_ok" = false ]; then
    echo ""
    echo "环境检查失败。请先准备以下环境:"
    echo "1. Java JDK 11+: https://www.oracle.com/java/"
    echo "2. Android SDK: https://developer.android.com/studio"
    echo "3. 设置环境变量:"
    echo "   export ANDROID_HOME=/path/to/android/sdk"
    exit 1
fi

echo "✅ 环境检查完成"
echo ""

# 配置 npm 以支持离线构建
echo "配置构建环境..."
npm config set registry https://registry.npmmirror.com --global
npm config set fetch-timeout 120000 --global

cd "$PROJECT_DIR"

# 如果需要，创建本地 node_modules
if [ ! -d "node_modules" ]; then
    echo "📦 安装必要的项目依赖..."
    npm install --no-audit --no-fund 2>&1 | tail -5
fi

# 检查 Cordova
if ! command -v cordova &> /dev/null; then
    if [ ! -f "node_modules/.bin/cordova" ]; then
        echo "安装 Cordova..."
        npm install cordova@latest --no-audit --no-fund 2>&1 | tail -3
    fi
    CORDOVA="$(pwd)/node_modules/.bin/cordova"
else
    CORDOVA="cordova"
fi

echo "✅ Cordova 就绪: $CORDOVA"
echo ""

# 添加 Android 平台
echo "设置 Android 平台..."
if [ ! -d "platforms/android" ]; then
    $CORDOVA platform add android@latest
else
    echo "✅ Android 平台已存在"
fi

echo ""
echo "🔨 构建 Release APK..."
echo "════════════════════════════════════════"

# 执行构建
$CORDOVA build android --release 2>&1 | grep -E "(Building|Compiling|APK|Finished|BUILD|\[|error|Error|ERROR)" || true

echo ""
echo "检查构建输出..."

# 查找 APK 文件
APK_UNSIGNED="$PROJECT_DIR/platforms/android/app/build/outputs/apk/release/app-release-unsigned.apk"
APK_DEBUG="$PROJECT_DIR/platforms/android/app/build/outputs/apk/debug/app-debug.apk"

if [ -f "$APK_UNSIGNED" ]; then
    # 复制到输出目录
    cp "$APK_UNSIGNED" "$output_dir/bingyuege-v1.0.0-unsigned.apk"
    cp "$APK_UNSIGNED" "$output_dir/app-release-unsigned.apk"
    
    APK_SIZE=$(du -h "$APK_UNSIGNED" | cut -f1)
    APK_MD5=$(md5sum "$APK_UNSIGNED" | cut -d' ' -f1)
    
    echo ""
    echo "✅ APK 构建成功！"
    echo "════════════════════════════════════════"
    echo "文件: $(basename $APK_UNSIGNED)"
    echo "大小: $APK_SIZE"
    echo "MD5:  $APK_MD5"
    echo "位置: $output_dir/"
    echo ""
    
elif [ -f "$APK_DEBUG" ]; then
    cp "$APK_DEBUG" "$output_dir/app-debug.apk"
    echo "⚠️  只生成了 Debug APK (而不是 Release APK)"
    echo "位置: $output_dir/app-debug.apk"
else
    echo "❌ 未找到任何 APK 文件"
    echo "构建详情，请查看:"
    find "$PROJECT_DIR/platforms/android" -name "*.apk" 2>/dev/null || echo "未找到 APK"
    exit 1
fi

echo ""
echo "🎉 构建完成！"
echo ""
echo "下一步:"
echo "1️⃣  安装到设备:"
echo "    adb install -r '$output_dir/app-release-unsigned.apk'"
echo ""
echo "2️⃣  发布到 GitHub:"
echo "    export GITHUB_TOKEN=your_token_here"
echo "    ./github-release.sh v1.0.0"
echo ""
