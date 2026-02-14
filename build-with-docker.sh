#!/bin/bash

# ============================================
# 使用 Docker 构建 Android APK (避免本地环境问题)
# ============================================

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_IMAGE_NAME="bingyuege-builder:latest"
CONTAINER_NAME="bingyuege-build-$(date +%s)"

echo "╔════════════════════════════════════════╗"
echo "║     使用 Docker 构建 Android APK       ║"
echo "╚════════════════════════════════════════╝"

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装"
    echo "请访问 https://www.docker.com/get-started 安装 Docker"
    exit 1
fi

echo "✓ Docker 已安装: $(docker --version)"

# 创建 Dockerfile
cat > "$PROJECT_DIR/Dockerfile" << 'EOF'
FROM ubuntu:22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV ANDROID_SDK_ROOT=/opt/android-sdk-linux
ENV ANDROID_HOME=$ANDROID_SDK_ROOT
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools

# 安装依赖
RUN apt-get update && apt-get install -y \
    openjdk-11-jdk \
    wget \
    unzip \
    curl \
    git \
    build-essential \
    python3 \
    nodejs \
    npm \
    && apt-get clean

# 下载并安装 Android SDK
RUN mkdir -p $ANDROID_SDK_ROOT && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-9862488_latest.zip -O /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d $ANDROID_SDK_ROOT && \
    mkdir -p $ANDROID_SDK_ROOT/cmdline-tools/latest && \
    mv $ANDROID_SDK_ROOT/cmdline-tools/* $ANDROID_SDK_ROOT/cmdline-tools/latest/ && \
    rm /tmp/cmdline-tools.zip

# 安装 Android SDK 组件
RUN sdkmanager --sdk_root=$ANDROID_SDK_ROOT "platforms;android-34" \
    "build-tools;34.0.0" \
    "platform-tools" \
    --channel=0 2>&1 | tail -10 || true

# 安装 Node 依赖和 Cordova
RUN npm install -g cordova@latest --unsafe-perm

WORKDIR /app

CMD ["/bin/bash"]
EOF

echo "📦 构建 Docker 镜像..."
docker build -t "$BUILD_IMAGE_NAME" -f "$PROJECT_DIR/Dockerfile" "$PROJECT_DIR" 2>&1 | tail -20

echo "🔨 在容器中运行构建..."
docker run --rm \
    --name "$CONTAINER_NAME" \
    -v "$PROJECT_DIR:/app" \
    -e ANDROID_SDK_ROOT=/opt/android-sdk-linux \
    "$BUILD_IMAGE_NAME" \
    bash -c "
    set -e
    echo '📋 检查环境...'
    node --version
    npm --version
    cordova --version
    
    echo '📥 安装依赖...'
    cd /app
    npm install 2>&1 | grep -E '(added|up to date)' || true
    
    echo '⚙️ 初始化 Cordova...'
    cordova platform add android@latest 2>&1 | tail -10
    
    echo '🔨 构建 APK...'
    cordova build android --release 2>&1 | grep -E '(BUILD|success|error)' || true
    
    echo '✓ 构建完成!'
    ls -lh platforms/android/app/build/outputs/apk/release/ || echo '❌ 输出目录不存在'
    " 2>&1 | tee "$PROJECT_DIR/build/docker-build.log"

echo "✓ Docker 构建完成!"
echo "📂 输出文件在: $PROJECT_DIR/platforms/android/app/build/outputs/apk/release/"
