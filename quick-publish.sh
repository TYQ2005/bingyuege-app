#!/bin/bash

# 冰阅 APP 一键快速发布
# 最简单的 APK 发布方法

set -e

echo ""
echo "╔════════════════════════════════════════╗"
echo "║  冰阅 APP 一键快速发布工具 v1.0.0   ║"
echo "╚════════════════════════════════════════╝"
echo ""

# 检查必要的环境
echo "🔍 检查环境..."
command -v git >/dev/null 2>&1 || { echo "❌ Git not found"; exit 1; }
echo "✅ Git 已找到"

# 进入项目目录
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# 验证必要的脚本
if [ ! -f "publish-release.sh" ]; then
    echo "❌ 发布脚本未找到"
    exit 1
fi

echo ""
echo "📱 冰阅 APP 快速发布工作流"
echo "================================"
echo ""
echo "此脚本将："
echo "  1️⃣  验证您的开发环境"
echo "  2️⃣  选择构建方式（本地/Docker/GitHub Actions）"
echo "  3️⃣  自动构建 APK"
echo "  4️⃣  创建 GitHub Release"
echo "  5️⃣  上传 APK 文件"
echo ""

# 提示用户选择发布版本
echo "请选择版本："
echo "1) v1.0.0 (当前版本)"
echo "2) 自定义版本"
echo ""
read -p "请输入选号 (1-2): " VERSION_CHOICE

case $VERSION_CHOICE in
    1)
        VERSION="v1.0.0"
        ;;
    2)
        read -p "请输入版本号 (示例: v1.1.0): " VERSION
        if [[ ! $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "❌ 版本号格式错误"
            exit 1
        fi
        ;;
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac

echo ""
echo "🚀 开始发布流程... ($VERSION)"
echo ""

# 执行发布脚本
chmod +x "$PROJECT_DIR/publish-release.sh"
"$PROJECT_DIR/publish-release.sh" "$VERSION"

echo ""
echo "✨ 拜托了！"
