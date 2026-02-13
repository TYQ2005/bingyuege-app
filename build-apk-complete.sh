#!/bin/bash

# 冰阅 APP 完整 APK 构建脚本
# 从零开始构建发布版本 APK，无需复杂的环境配置

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build_output"
RELEASE_NOTES="冰阅阅读APP v1.0.0 发布版本构建"

echo ""
echo "╔════════════════════════════════════════════════╗"
echo "║  冰阅 APP APK 构建系统 v1.0.0                 ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# 步骤 1: 环境检查
log_info "步骤 1/7: 检查构建环境..."

if ! command -v java &> /dev/null; then
    log_error "Java JDK 未找到"
    echo ""
    echo "请安装 Java JDK 11+:"
    echo "  Ubuntu/Debian: sudo apt-get install openjdk-11-jdk"
    echo "  macOS: brew install openjdk@11"
    echo "  Windows: 访问 https://www.oracle.com/java/technologies/downloads/"
    exit 1
fi
JAVA_VERSION=$(java -version 2>&1 | grep version | cut -d' ' -f3 | tr -d '"')
log_success "Java 版本: $JAVA_VERSION"

if ! command -v gradle &> /dev/null; then
    log_error "Gradle 未找到"
    echo ""
    echo "请安装 Gradle:"
    echo "  Ubuntu/Debian: sudo apt-get install gradle"
    echo "  macOS: brew install gradle"
    exit 1
fi
GRADLE_VERSION=$(gradle --version 2>&1 | head -1)
log_success "Gradle 已安装: $GRADLE_VERSION"

# 步骤 2: 环境变量设置
log_info "步骤 2/7: 设置构建环境..."

if [ -z "$ANDROID_HOME" ]; then
    # 尝试自动检测 Android SDK
    if [ -d "$HOME/Android/Sdk" ]; then
        export ANDROID_HOME="$HOME/Android/Sdk"
    elif [ -d "/opt/android-sdk" ]; then
        export ANDROID_HOME="/opt/android-sdk"
    else
        log_error "ANDROID_HOME 未设置且 Android SDK 未找到"
        echo ""
        echo "请设置 ANDROID_HOME:"
        echo "  export ANDROID_HOME=\$HOME/Android/Sdk"
        echo "  export PATH=\$PATH:\$ANDROID_HOME/tools:\$ANDROID_HOME/platform-tools"
        exit 1
    fi
fi

if [ ! -d "$ANDROID_HOME" ]; then
    log_error "ANDROID_HOME 指向的目录不存在: $ANDROID_HOME"
    exit 1
fi

log_success "ANDROID_HOME: $ANDROID_HOME"
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# 步骤 3: 项目配置
log_info "步骤 3/7: 检查项目文件..."

if [ ! -f "$PROJECT_DIR/config.xml" ]; then
    log_error "config.xml 未找到"
    exit 1
fi
log_success "config.xml 已找到"

if [ ! -f "$PROJECT_DIR/www/index.html" ]; then
    log_error "www/index.html 未找到"
    exit 1
fi
log_success "www/index.html 已找到 ($(du -h "$PROJECT_DIR/www/index.html" | cut -f1))"

if [ ! -f "$PROJECT_DIR/package.json" ]; then
    log_error "package.json 未找到"
    exit 1
fi
log_success "package.json 已找到"

# 步骤 4: 准备构建目录
log_info "步骤 4/7: 准备构建目录..."

if [ -d "$PROJECT_DIR/platforms/android" ]; then
    log_warn "检测到旧的 Android 平台目录，清理中..."
    rm -rf "$PROJECT_DIR/platforms" "$PROJECT_DIR/plugins"
fi

mkdir -p "$BUILD_DIR"
log_success "构建目录已准备"

# 步骤 5: 安装 Cordova
log_info "步骤 5/7: 安装 Cordova..."

cd "$PROJECT_DIR"

if ! command -v cordova &> /dev/null; then
    log_warn "Cordova CLI 未全局安装，使用 npx 调用..."
    CORDOVA="npx cordova"
else
    CORDOVA="cordova"
    log_success "Cordova 已全局安装"
fi

# 步骤 6: 构建安卓平台
log_info "步骤 6/7: 构建 Android 平台..."

$CORDOVA platform add android@latest 2>&1 | tail -5
log_success "Android 平台已添加"

# 步骤 7: 编译 Release APK
log_info "步骤 7/7: 编译 Release APK..."
echo "这可能需要 5-15 分钟，请耐心等待..."
echo ""

$CORDOVA build android --release 2>&1 | tee "$BUILD_DIR/build.log"

# 查找输出的 APK
echo ""
log_info "查找构建输出..."

APK_UNSIGNED="$PROJECT_DIR/platforms/android/app/build/outputs/apk/release/app-release-unsigned.apk"
APK_SIGNED="$PROJECT_DIR/platforms/android/app/build/outputs/apk/release/app-release.apk"
APK_DEBUG="$PROJECT_DIR/platforms/android/app/build/outputs/apk/debug/app-debug.apk"

if [ -f "$APK_UNSIGNED" ]; then
    APK_FILE="$APK_UNSIGNED"
    log_success "找到无签名 APK: $(du -h "$APK_FILE" | cut -f1)"
elif [ -f "$APK_SIGNED" ]; then
    APK_FILE="$APK_SIGNED"
    log_success "找到已签名 APK: $(du -h "$APK_FILE" | cut -f1)"
elif [ -f "$APK_DEBUG" ]; then
    APK_FILE="$APK_DEBUG"
    log_warn "只找到 Debug APK: $(du -h "$APK_FILE" | cut -f1)"
else
    log_error "未找到任何 APK 文件"
    echo ""
    echo "构建可能失败。请查看日志:"
    echo "  tail -50 $BUILD_DIR/build.log"
    exit 1
fi

# 复制到构建输出目录
cp "$APK_FILE" "$BUILD_DIR/$(basename $APK_FILE)"
log_success "APK 已复制到: $BUILD_DIR/"

# 显示构建信息
echo ""
echo "╔════════════════════════════════════════════════╗"
echo "║         ✨ 构建完成！                         ║"
echo "╚════════════════════════════════════════════════╝"
echo ""
echo "📦 APK 文件信息:"
echo "  路径: $APK_FILE"
echo "  大小: $(du -h "$APK_FILE" | cut -f1)"
echo "  MD5:  $(md5sum "$APK_FILE" | cut -d' ' -f1)"
echo ""
echo "📱 安装到设备:"
echo "  adb install -r \"$APK_FILE\""
echo ""
echo "📤 发布到 GitHub Releases:"
echo "  export GITHUB_TOKEN=your_token"
echo "  ./github-release.sh v1.0.0"
echo ""
echo "✅ 构建成功！APK 已保存到: $BUILD_DIR/"
echo ""
