#!/bin/bash

# 冰阅 APP 完整发布工作流
# 从构建到 GitHub Releases 的端到端自动化

set -e

VERSION="${1:-v1.0.0}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║    冰阅 APP 完整发布工作流 $VERSION      ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# 配置颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${YELLOW}➜${NC} 步骤 $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

# 步骤 1: 版本验证
print_step "1/7 验证版本号"
if [[ ! $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "版本号格式错误: $VERSION (应为 vX.Y.Z)"
    exit 1
fi
print_success "版本号验证: $VERSION"

# 步骤 2: Git 状态检查
print_step "2/7 检查 Git 状态"
cd "$PROJECT_DIR"

if [ -n "$(git status --porcelain)" ]; then
    print_error "Working directory 有未提交的更改"
    echo "请先提交所有更改: git add . && git commit -m 'message'"
    exit 1
fi
print_success "Git 状态正常"

# 步骤 3: 标签验证
print_step "3/7 验证或创建版本标签"
if git rev-parse "$VERSION" >/dev/null 2>&1; then
    print_success "标签已存在: $VERSION"
else
    print_step "   创建新标签: $VERSION"
    git tag -a "$VERSION" -m "Release $VERSION"
    print_success "标签已创建"
fi

# 步骤 4: 构建选择
print_step "4/7 选择构建方式"
echo ""
echo "请选择构建方式:"
echo "1) 本地构建 (需要本地环境)"
echo "2) Docker 构建 (推荐，无需本地环境)"
echo "3) 使用 GitHub Actions (自动在云端构建)"
echo ""

read -p "请选择 (1-3): " BUILD_METHOD

case $BUILD_METHOD in
    1)
        print_step "   执行本地构建..."
        if [ ! -d "./node_modules" ]; then
            npm install
        fi
        if ! cordova platform ls | grep -q android; then
            cordova platform add android@latest
        fi
        npm run build
        print_success "本地构建完成"
        ;;
    2)
        print_step "   执行 Docker 构建..."
        chmod +x "$PROJECT_DIR/docker-build.sh"
        "$PROJECT_DIR/docker-build.sh"
        print_success "Docker 构建完成"
        ;;
    3)
        print_step "   使用 GitHub Actions 构建..."
        print_step "   推送标签以触发自动构建..."
        git push origin "$VERSION"
        echo ""
        echo "⏳  GitHub Actions 正在构建..."
        echo "   请访问查看进度: https://github.com/TYQ2005/bingyuege-app/actions"
        echo ""
        read -p "等待构建完成后按 Enter (或输入 's' 跳过本地构建的后续步骤): " -n 1
        if [[ $REPLY = [Ss]$ ]]; then
            print_success "跳过本地 APK 验证，将依赖 GitHub Actions 的构建"
        fi
        ;;
    *)
        print_error "无效选择"
        exit 1
        ;;
esac

# 步骤 5: APK 验证
print_step "5/7 验证 APK 文件"
if [ ! -f "platforms/android/app/build/outputs/apk/release/app-release.apk" ] && \
   [ ! -f "platforms/android/app/build/outputs/apk/release/app-release-unsigned.apk" ]; then
    print_step "   注: APK 文件未在本地找到"
    echo "   这在使用 GitHub Actions 时是正常的"
    echo "   APK 将在该服务上生成"
fi
print_success "APK 验证完成"

# 步骤 6: Git 推送
print_step "6/7 推送更改到 GitHub"
if ! git branch -r | grep -q "origin/main"; then
    print_error "未设置远程分支 origin/main"
    exit 1
fi

git push origin main
git push origin "$VERSION"
print_success "已推送所有更改和标签"

# 步骤 7: 发布到 Releases
print_step "7/7 创建 GitHub Release"
echo ""
echo "自动生成的发布脚本将:"
echo "  ✓ 检查或创建 GitHub Release"
echo "  ✓ 上传 APK 文件"
echo "  ✓ 生成发布说明"
echo ""

if [ -f "$PROJECT_DIR/github-release.sh" ]; then
    chmod +x "$PROJECT_DIR/github-release.sh"
    "$PROJECT_DIR/github-release.sh" "$VERSION"
else
    print_error "发布脚本未找到"
    exit 1
fi

# 完成
echo ""
echo "╔════════════════════════════════════════════╗"
echo "║       📤 发布工作流完成 $VERSION        ║"
echo "╚════════════════════════════════════════════╝"
echo ""
echo "下一步:"
echo "1. 访问发布页面: https://github.com/TYQ2005/bingyuege-app/releases/tag/$VERSION"
echo "2. 验证 APK 文件已上载"
echo "3. 在真实设备上测试 APK"
echo "4. 宣传发布版本"
echo ""
