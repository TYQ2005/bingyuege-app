#!/bin/bash

# 冰阅 APP Docker 构建脚本
# 用于在 Docker 容器中构建 Android APK，避免本地环境问题

set -e

PROJECT_NAME="bingyuege-app"
PROJECT_DIR="$(pwd)"
DOCKER_IMAGE="circleci/android:android-30-node"
BUILD_OUTPUT="$PROJECT_DIR/platforms/android/app/build/outputs/apk"

echo "🐳 冰阅 APP Docker 构建系统"
echo "================================"

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装。请先安装 Docker"
    echo "   访问：https://docs.docker.com/get-docker/"
    exit 1
fi

# 清理旧的构建输出
echo "🧹 清理旧的构建文件..."
rm -rf "$PROJECT_DIR/platforms" "$PROJECT_DIR/node_modules" "$PROJECT_DIR/package-lock.json"

# 创建 Dockerfile
echo "📝 创建 Dockerfile..."
cat > "$PROJECT_DIR/Dockerfile.build" << 'EOF'
FROM circleci/android:android-30-node

# 安装必要的工具
RUN npm install -g cordova cordova-res

# 设置工作目录
WORKDIR /app

# 复制项目文件
COPY . .

# 安装依赖
RUN npm install --registry https://registry.npmmirror.com

# 添加 Android 平台
RUN cordova platform add android@latest

# 构建 Release APK
RUN cordova build android --release

# 保留已构建的 APK
CMD ["/bin/bash"]
EOF

# 构建 Docker 镜像
echo "🔨 构建 Docker 镜像..."
docker build \
    -f "$PROJECT_DIR/Dockerfile.build" \
    -t "${PROJECT_NAME}-builder:latest" \
    "$PROJECT_DIR"

# 运行容器并提取构建的 APK
echo "⚙️  运行构建容器..."
CONTAINER_ID=$(docker run -d \
    -v "$PROJECT_DIR/platforms:/app/platforms" \
    "${PROJECT_NAME}-builder:latest" \
    /bin/sleep 300)

# 等待容器就绪
sleep 5

# 复制构建输出
echo "📦 提取构建输出..."
docker cp "$CONTAINER_ID:/app/platforms" "$PROJECT_DIR/" || true

# 停止容器
docker stop "$CONTAINER_ID" || true
docker rm "$CONTAINER_ID" || true

# 检查是否构建成功
if [ -d "$BUILD_OUTPUT" ]; then
    echo ""
    echo "✅ 构建成功！"
    echo "================================"
    find "$BUILD_OUTPUT" -name "*.apk" -type f -exec ls -lh {} \;
    echo ""
    echo "APK 文件位置："
    find "$BUILD_OUTPUT" -name "*.apk" -type f
else
    echo "❌ 构建失败。APK 未找到。"
    exit 1
fi

echo ""
echo "🎉 Docker 构建完成！"
echo "================================"
