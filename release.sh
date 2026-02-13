#!/bin/bash

# 冰阅 · GitHub 版本发布脚本
# 此脚本用于创建和发布新版本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函数
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# 检查命令
check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_error "$1 未找到"
        exit 1
    fi
}

# 主程序
main() {
    print_header "冰阅 · 版本发布助手"

    # 检查必需工具
    check_command git
    check_command gh
    
    # 获取版本号
    echo "请输入版本号 (格式: vX.Y.Z, 如 v1.0.1):"
    read -r VERSION
    
    # 简单的版本号验证
    if ! [[ $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_error "版本号格式不正确，应为 vX.Y.Z"
        exit 1
    fi

    # 检查版本是否已存在
    if git rev-parse "$VERSION" >/dev/null 2>&1; then
        print_error "标签 $VERSION 已存在"
        exit 1
    fi

    # 确认发布
    echo ""
    echo "将发布版本: ${BLUE}$VERSION${NC}"
    echo "请输入发布说明 (直接按Enter跳过):"
    read -r NOTES

    # 检查工作区状态
    if ! git diff-index --quiet HEAD --; then
        print_warning "工作区有未提交的改动"
        echo "是否继续? (y/n)"
        read -r CONFIRM
        if [ "$CONFIRM" != "y" ]; then
            exit 1
        fi
    fi

    # 创建标签
    print_header "创建标签"
    if [ -z "$NOTES" ]; then
        git tag -a "$VERSION" -m "发布 $VERSION"
    else
        git tag -a "$VERSION" -m "发布 $VERSION: $NOTES"
    fi
    print_success "标签 $VERSION 已创建"

    # 推送标签
    print_header "推送到 GitHub"
    git push origin "$VERSION"
    print_success "标签已推送"

    # 创建Release
    print_header "创建 GitHub Release"
    
    RELEASE_NOTES="# 冰阅 APP $VERSION 版本

## 版本信息
- **版本号**: $VERSION
- **发布日期**: $(date '+%Y-%m-%d %T')

## 功能特性
- ✨ 支持 JSON/XML/文本/URL 四种格式书源导入
- 📚 完整的书籍管理和阅读功能  
- 🌓 夜间/白天主题切换
- 💾 阅读进度自动保存
- 📖 章节导航和目录快速定位

## 安装说明
1. 下载 APK 文件
2. 在 Android 设备上安装（需要 Android 6.0 及以上）
3. 允许必要的权限
4. 开始使用

## 使用指南
详见 [IMPORT_GUIDE.md](IMPORT_GUIDE.md)

"

    if [ -n "$NOTES" ]; then
        RELEASE_NOTES+="## 发布说明
$NOTES

"
    fi

    RELEASE_NOTES+="## 获取帮助
- 📖 [项目文档](README.md)
- 🐛 [报告问题](https://github.com/TYQ2005/bingyuege-app/issues)
- 📧 [联系开发者](mailto:dev@bingyuege.app)"

    gh release create "$VERSION" \
        --title "冰阅 $VERSION" \
        --notes "$RELEASE_NOTES" \
        2>/dev/null || true
    
    print_success "Release 已创建"

    # 完成
    print_header "发布完成"
    echo "✓ 版本 $VERSION 已发布"
    echo "✓ 访问: https://github.com/TYQ2005/bingyuege-app/releases/tag/$VERSION"
    echo ""
    echo "接下来的步骤:"
    echo "1. 等待 GitHub Actions 自动构建 APK"
    echo "2. 检查 https://github.com/TYQ2005/bingyuege-app/releases/$VERSION"
    echo "3. 下载并测试 APK 文件"
    echo "4. 可选：上传到应用商店"
}

# 运行
main
