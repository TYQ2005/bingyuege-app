#!/bin/bash

# ============================================
# 冰阅 Android APK 完整构建和发布脚本 (v2.0)
# ============================================

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
RELEASE_DIR="$PROJECT_DIR/release"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
VERSION=$(grep '"version"' "$PROJECT_DIR/package.json" | sed -E 's/.*"version":\s*"([^"]+)".*/\1/')

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# 检查环境
check_environment() {
    log_info "检查开发环境..."
    
    # 检查必要工具
    local tools=("node" "npm" "git")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "$tool 未安装"
            exit 1
        fi
    done
    
    log_info "Node.js 版本: $(node --version)"
    log_info "npm 版本: $(npm --version)"
    
    # 检查Android SDK
    if [ -z "$ANDROID_SDK_ROOT" ] && [ -z "$ANDROID_HOME" ]; then
        log_warning "未配置 ANDROID_SDK_ROOT 或 ANDROID_HOME"
        log_info "尝试使用默认路径..."
        export ANDROID_SDK_ROOT="$HOME/Android/sdk"
    fi
    
    log_success "环境检查完成"
}

# 清理旧文件
cleanup() {
    log_info "清理旧构建文件..."
    rm -rf "$BUILD_DIR" "$PROJECT_DIR/platforms" "$PROJECT_DIR/plugins" "$PROJECT_DIR/node_modules"
    mkdir -p "$BUILD_DIR" "$RELEASE_DIR"
    log_success "清理完成"
}

# 安装依赖
install_dependencies() {
    log_info "安装项目依赖..."
    
    # 安装 npm 依赖
    npm install 2>&1 | grep -E "(added|up to date|audited)" || true
    
    # 全局安装 Cordova (使用 npm 本地缓存)
    if ! command -v cordova &> /dev/null; then
        log_info "安装 Cordova CLI..."
        npm install -g cordova@latest --legacy-peer-deps 2>&1 | tail -5 || {
            log_warning "Cordova 全局安装失败，尝试本地安装"
            npm install cordova@latest --save-dev
        }
    fi
    
    log_success "依赖安装完成"
}

# 初始化 Cordova
init_cordova() {
    log_info "初始化 Cordova 项目..."
    
    cd "$PROJECT_DIR"
    
    # 添加 Android 平台
    local cordova_cmd="npx cordova"
    if command -v cordova &> /dev/null; then
        cordova_cmd="cordova"
    fi
    
    # 检查平台是否已存在
    if [ ! -d "$PROJECT_DIR/platforms/android" ]; then
        log_info "添加 Android 平台..."
        $cordova_cmd platform add android@latest 2>&1 | tail -10
    else
        log_info "Android 平台已存在"
    fi
    
    log_success "Cordova 初始化完成"
}

# 更新配置
update_config() {
    log_info "更新应用配置..."
    
    # 更新 config.xml (已有，无需修改)
    log_info "应用ID: com.bingyuege.app"
    log_info "应用版本: $VERSION"
    log_info "最小 Android API: 23 (Android 6.0)"
    
    log_success "配置更新完成"
}

# 构建 Debug APK
build_debug() {
    log_info "构建 Debug APK..."
    
    cd "$PROJECT_DIR"
    local cordova_cmd="npx cordova"
    if command -v cordova &> /dev/null; then
        cordova_cmd="cordova"
    fi
    
    $cordova_cmd build android --debug 2>&1 | tee "$BUILD_DIR/debug_build.log" | grep -E "(BUILD|Error|error|APK)" || true
    
    # 查找生成的 APK
    if [ -f "$PROJECT_DIR/platforms/android/app/build/outputs/apk/debug/app-debug.apk" ]; then
        cp "$PROJECT_DIR/platforms/android/app/build/outputs/apk/debug/app-debug.apk" \
           "$RELEASE_DIR/bingyuege-app-debug-${VERSION}-${TIMESTAMP}.apk"
        log_success "Debug APK 构建成功: bingyuege-app-debug-${VERSION}-${TIMESTAMP}.apk"
    else
        log_error "Debug APK 构建失败"
        return 1
    fi
}

# 构建 Release APK
build_release() {
    log_info "构建 Release APK..."
    
    cd "$PROJECT_DIR"
    local cordova_cmd="npx cordova"
    if command -v cordova &> /dev/null; then
        cordova_cmd="cordova"
    fi
    
    $cordova_cmd build android --release 2>&1 | tee "$BUILD_DIR/release_build.log" | grep -E "(BUILD|Error|error|APK)" || true
    
    # 查找生成的 APK
    if [ -f "$PROJECT_DIR/platforms/android/app/build/outputs/apk/release/app-release-unsigned.apk" ]; then
        cp "$PROJECT_DIR/platforms/android/app/build/outputs/apk/release/app-release-unsigned.apk" \
           "$RELEASE_DIR/bingyuege-app-release-${VERSION}-${TIMESTAMP}-unsigned.apk"
        log_success "Release APK 构建成功 (未签名): bingyuege-app-release-${VERSION}-${TIMESTAMP}-unsigned.apk"
    else
        log_error "Release APK 构建失败"
        return 1
    fi
}

# 生成签名密钥 (如果需要)
generate_signing_key() {
    log_info "配置应用签名..."
    
    local keystore="$PROJECT_DIR/.keystore"
    if [ ! -f "$keystore" ]; then
        log_warning "未找到签名文件，跳过签名步骤"
        log_info "要创建签名文件，运行:"
        log_info "  keytool -genkey -v -keystore $keystore -keyalg RSA -keysize 2048 -validity 10000 -alias bingyuege"
        return 0
    fi
    
    log_success "签名配置完成"
}

# 生成构建报告
generate_report() {
    log_info "生成构建报告..."
    
    local report="$BUILD_DIR/BUILD_REPORT_${TIMESTAMP}.txt"
    {
        echo "====== 冰阅 Android APK 构建报告 ======"
        echo "构建时间: $(date)"
        echo "构建版本: $VERSION"
        echo "项目目录: $PROJECT_DIR"
        echo ""
        echo "====== 系统信息 ======"
        echo "操作系统: $(uname -s)"
        echo "Node.js: $(node --version)"
        echo "npm: $(npm --version)"
        echo ""
        echo "====== 构建输出 ======"
        ls -lh "$RELEASE_DIR"/*.apk 2>/dev/null || echo "未找到 APK 文件"
        echo ""
        echo "====== 构建日志 ======"
        if [ -f "$BUILD_DIR/debug_build.log" ]; then
            echo "Debug 日志:"
            tail -20 "$BUILD_DIR/debug_build.log"
        fi
        if [ -f "$BUILD_DIR/release_build.log" ]; then
            echo "Release 日志:"
            tail -20 "$BUILD_DIR/release_build.log"
        fi
    } > "$report"
    
    log_success "构建报告已保存: $report"
}

# 主函数
main() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════╗"
    echo "║   冰阅 Android APK 构建和发布系统      ║"
    echo "║          v2.0 - 完整构建流程           ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log_info "开始构建流程..."
    log_info "版本号: $VERSION"
    
    # 执行构建步骤
    check_environment
    cleanup
    install_dependencies
    init_cordova
    update_config
    generate_signing_key
    
    # 询问要构建的类型
    echo ""
    echo "选择构建类型:"
    echo "1) Debug APK"
    echo "2) Release APK (未签名)"
    echo "3) 两者都构建"
    echo ""
    read -p "请选择 [1-3]: " build_choice
    
    case $build_choice in
        1)
            build_debug
            ;;
        2)
            build_release
            ;;
        3)
            build_debug || true
            build_release || true
            ;;
        *)
            log_error "无效选择"
            exit 1
            ;;
    esac
    
    generate_report
    
    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    log_success "构建流程完成!"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    
    log_info "输出文件位置: $RELEASE_DIR"
    ls -lh "$RELEASE_DIR"/*.apk 2>/dev/null || log_warning "未生成 APK 文件"
    
    echo ""
    log_info "后续步骤:"
    echo "  1. 测试 APK: adb install -r <apk_file>"
    echo "  2. 签名 APK: jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore .keystore <unsigned_apk> bingyuege"
    echo "  3. 优化 zipalign: zipalign -v 4 <signed_apk> <aligned_apk>"
    echo "  4. 发布到 GitHub: gh release create v$VERSION <apk_file>"
}

# 执行主函数
main "$@"
