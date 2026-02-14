#!/bin/bash

# 冰阅 APP 完整构建脚本 v2.0
# 支持多种构建方案和恢复机制

set -e

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${COLOR_BLUE}================================================${NC}"
echo -e "${COLOR_BLUE}  冰阅 APP - 完整构建系统 v2.0${NC}"
echo -e "${COLOR_BLUE}================================================${NC}"
echo ""

# ==================== 配置 ====================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
BUILD_LOG="$PROJECT_DIR/build-log.txt"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

log() {
    echo "[${TIMESTAMP}] $1" >> "$BUILD_LOG"
    echo -e "${COLOR_GREEN}✓${NC} $1"
}

error() {
    echo "[${TIMESTAMP}] ERROR: $1" >> "$BUILD_LOG"
    echo -e "${COLOR_RED}✗${NC} ERROR: $1"
    exit 1
}

warning() {
    echo "[${TIMESTAMP}] WARNING: $1" >> "$BUILD_LOG"
    echo -e "${COLOR_YELLOW}⚠${NC} WARNING: $1"
}

info() {
    echo -e "${COLOR_BLUE}ℹ${NC} $1"
}

# ==================== 检查环境 ====================
check_environment() {
    info "检查构建环境..."
    echo "" >> "$BUILD_LOG"
    echo "=== 环境检查 ===" >> "$BUILD_LOG"
    
    # Java
    if ! command -v java &> /dev/null; then
        error "未找到 Java，请安装 JDK 11+"
    fi
    JAVA_VERSION=$(java -version 2>&1 | grep version | awk '{print $3}' | tr -d '"')
    log "Java 版本: $JAVA_VERSION"
    
    # Node.js
    if ! command -v node &> /dev/null; then
        error "未找到 Node.js，请安装 Node.js 14+"
    fi
    NODE_VERSION=$(node -v)
    log "Node.js 版本: $NODE_VERSION"
    
    # npm
    if ! command -v npm &> /dev/null; then
        error "未找到 npm"
    fi
    NPM_VERSION=$(npm -v)
    log "npm 版本: $NPM_VERSION"
    
    echo ""
}

# ==================== 清理环境 ====================
clean_environment() {
    info "清理构建环境..."
    
    if [ -d "$PROJECT_DIR/platforms" ]; then
        warning "删除旧的 platforms 目录..."
        rm -rf "$PROJECT_DIR/platforms"
        log "已删除 platforms"
    fi
    
    if [ -d "$PROJECT_DIR/plugins" ]; then
        warning "删除旧的 plugins 目录..."
        rm -rf "$PROJECT_DIR/plugins"
        log "已删除 plugins"
    fi
    
    echo ""
}

# ==================== 修复 npm 问题 ====================
fix_npm() {
    info "修复 npm 配置..."
    
    # 清理 npm 缓存
    warning "清理 npm 缓存..."
    npm cache clean --force >> "$BUILD_LOG" 2>&1 || true
    
    # 设置 npm 镜像
    info "配置 npm 镜像..."
    NPM_REGISTRY="${NPM_REGISTRY:-https://registry.npmmirror.com}"
    npm config set registry "$NPM_REGISTRY" >> "$BUILD_LOG" 2>&1
    log "npm 镜像: $NPM_REGISTRY"
    
    # 增加超时时间
    npm config set fetch-timeout 60000 >> "$BUILD_LOG" 2>&1
    npm config set fetch-retry-mintimeout 10000 >> "$BUILD_LOG" 2>&1
    npm config set fetch-retry-maxtimeout 60000 >> "$BUILD_LOG" 2>&1
    log "增加 npm 超时配置"
    
    echo ""
}

# ==================== 安装依赖 ====================
install_dependencies() {
    info "安装项目依赖..."
    
    cd "$PROJECT_DIR"
    
    # 尝试安装
    if npm install --prefer-offline --no-audit 2>&1 | tee -a "$BUILD_LOG"; then
        log "依赖安装成功"
    else
        warning "使用离线模式安装失败，尝试强制安装..."
        if npm install --force 2>&1 | tee -a "$BUILD_LOG"; then
            log "强制安装成功"
        else
            error "依赖安装失败，请检查网络连接和 npm 配置"
        fi
    fi
    
    # 验证关键依赖
    if [ ! -d "$PROJECT_DIR/node_modules/cordova-android" ]; then
        info "cordova-android 未安装，手动安装..."
        npm install cordova-android@12.0.0 >> "$BUILD_LOG" 2>&1 || true
    fi
    
    echo ""
}

# ==================== 添加 Android 平台 ====================
add_android_platform() {
    info "添加 Android 平台..."
    
    cd "$PROJECT_DIR"
    
    if [ ! -d "$PROJECT_DIR/platforms/android" ]; then
        if npx cordova platform add android@latest >> "$BUILD_LOG" 2>&1; then
            log "Android 平台添加成功"
        else
            error "Android 平台添加失败"
        fi
    else
        log "Android 平台已存在"
    fi
    
    echo ""
}

# ==================== 构建 APK ====================
build_apk() {
    local BUILD_TYPE="${1:-debug}"
    
    info "构建 $BUILD_TYPE APK..."
    echo "[开始构建] 类型: $BUILD_TYPE" >> "$BUILD_LOG"
    
    cd "$PROJECT_DIR"
    
    START_TIME=$(date +%s)
    
    if npx cordova build android --"$BUILD_TYPE" 2>&1 | tee -a "$BUILD_LOG"; then
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        
        log "$BUILD_TYPE 版本构建成功（耗时 ${DURATION}s）"
        echo ""
        
        return 0
    else
        error "构建失败，请查看 $BUILD_LOG 中的详细错误信息"
        return 1
    fi
}

# ==================== 查找 APK 文件 ====================
find_apk() {
    info "查找生成的 APK 文件..."
    
    local BUILD_TYPE="${1:-debug}"
    local APK_DIR="$PROJECT_DIR/platforms/android/app/build/outputs/apk"
    
    if [ -d "$APK_DIR/$BUILD_TYPE" ]; then
        local APK_FILE=$(find "$APK_DIR/$BUILD_TYPE" -name "*.apk" | head -1)
        
        if [ -n "$APK_FILE" ]; then
            local FILE_SIZE=$(du -h "$APK_FILE" | cut -f1)
            log "APK 文件: $APK_FILE"
            log "文件大小: $FILE_SIZE"
            echo ""
            echo -e "${COLOR_GREEN}========================================${NC}"
            echo -e "${COLOR_GREEN}  构建完成！${NC}"
            echo -e "${COLOR_GREEN}========================================${NC}"
            echo ""
            echo "APK 位置: $APK_FILE"
            echo "大小: $FILE_SIZE"
            echo ""
            return 0
        fi
    fi
    
    warning "未找到 APK 文件"
    return 1
}

# ==================== 安装到设备 ====================
install_to_device() {
    local BUILD_TYPE="${1:-debug}"
    
    info "检查 Android 设备..."
    
    if ! command -v adb &> /dev/null; then
        warning "未找到 ADB 工具，跳过设备安装"
        return 1
    fi
    
    if ! adb devices | grep -q "device"; then
        warning "未连接 Android 设备"
        return 1
    fi
    
    local APK_FILE=$(find "$PROJECT_DIR/platforms/android/app/build/outputs/apk/$BUILD_TYPE" -name "*.apk" | head -1)
    
    if [ -n "$APK_FILE" ]; then
        info "安装到设备..."
        adb install -r "$APK_FILE" >> "$BUILD_LOG" 2>&1 && \
        log "应用已安装到设备" && \
        return 0
    fi
    
    return 1
}

# ==================== 主程序 ====================
main() {
    echo "timestamp: $TIMESTAMP" > "$BUILD_LOG"
    
    # 步骤 1: 检查环境
    check_environment
    
    # 步骤 2: 清理环境
    read -p "是否清理之前的构建文件？(y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        clean_environment
    fi
    
    # 步骤 3: 修复 npm
    fix_npm
    
    # 步骤 4: 安装依赖
    install_dependencies
    
    # 步骤 5: 添加 Android 平台
    add_android_platform
    
    # 步骤 6: 选择构建类型
    info "选择构建类型:"
    echo "1) Debug (快速测试)"
    echo "2) Release (上架应用商店)"
    echo "3) 两者都构建"
    read -p "请选择 (1-3): " BUILD_CHOICE
    
    case $BUILD_CHOICE in
        1)
            build_apk "debug" && find_apk "debug"
            ;;
        2)
            warning "Release 版本需要签名密钥，请参考文档"
            build_apk "release" && find_apk "release"
            ;;
        3)
            build_apk "debug" && find_apk "debug"
            build_apk "release" && find_apk "release"
            ;;
        *)
            warning "无效选择，默认构建 Debug 版本"
            build_apk "debug" && find_apk "debug"
            ;;
    esac
    
    # 步骤 7: 可选安装到设备
    read -p "是否安装到已连接的设备？(y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_to_device "debug"
    fi
    
    echo ""
    echo "📋 构建日志已保存到: $BUILD_LOG"
    echo ""
}

# 执行主程序
main "$@"
