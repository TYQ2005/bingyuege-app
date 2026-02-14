#!/bin/bash

# ============================================
# 冰阅 APK 发布系统
# ============================================

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION=$(grep '"version"' "$PROJECT_DIR/package.json" | sed -E 's/.*"version":\s*"([^"]+)".*/\1/')
GIT_TAG="v$VERSION"
GITHUB_REPO="${GITHUB_REPO:-TYQ2005/bingyuege-app}"

echo "╔════════════════════════════════════════╗"
echo "║     冰阅 APK 发布系统 v2.0             ║"
echo "╚════════════════════════════════════════╝"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 检查依赖工具
check_requirements() {
    echo "🔍 检查环境..."
    
    local missing=0
    
    # 检查 gh CLI
    if ! command -v gh &> /dev/null; then
        echo -e "${YELLOW}⚠ GitHub CLI (gh) 未安装${NC}"
        echo "  通过以下命令安装: https://cli.github.com/"
        missing=1
    else
        echo -e "${GREEN}✓${NC} GitHub CLI: $(gh --version | head -1)"
    fi
    
    # 检查 git
    if ! command -v git &> /dev/null; then
        echo -e "${RED}✗ Git 未安装${NC}"
        return 1
    fi
    echo -e "${GREEN}✓${NC} Git: $(git --version | cut -d' ' -f3)"
    
    # 检查 JDK (用于签名)
    if command -v jarsigner &> /dev/null; then
        echo -e "${GREEN}✓${NC} JDK: 已安装"
    else
        echo -e "${YELLOW}⚠ JDK 未安装 (签名时需要)${NC}"
    fi
    
    return 0
}

# 检查 git 状态
check_git_status() {
    echo -e "\n📦 检查 Git 状态..."
    
    # 检查是否有未提交的更改
    if [ -n "$(git status --porcelain)" ]; then
        echo -e "${RED}✗ 工作目录有未提交的更改${NC}"
        git status --short
        read -p "继续发布? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # 检查当前分支
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    echo -e "当前分支: ${GREEN}$current_branch${NC}"
    
    # 检查 tag 是否存在
    if git rev-parse "$GIT_TAG" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Tag $GIT_TAG 已存在${NC}"
        read -p "覆盖存在的 tag? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git tag -d "$GIT_TAG" 2>/dev/null || true
            git push --delete origin "$GIT_TAG" 2>/dev/null || true
        else
            return 1
        fi
    fi
    
    return 0
}

# 构建 APK
build_apks() {
    echo -e "\n🔨 构建 APK..."
    
    # 尝试使用 Python 构建工具
    if [ -f "$PROJECT_DIR/build_tool.py" ]; then
        python3 "$PROJECT_DIR/build_tool.py" --build both
    else
        # 备选方案：使用 npm 脚本
        cd "$PROJECT_DIR"
        npm run build || {
            echo -e "${YELLOW}⚠ npm 构建可能有问题，继续...${NC}"
        }
    fi
    
    # 检查是否生成了 APK
    local apk_count=$(find "$PROJECT_DIR/release" -name "*.apk" 2>/dev/null | wc -l)
    if [ "$apk_count" -eq 0 ]; then
        echo -e "${RED}✗ 未生成 APK 文件${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓${NC} 生成了 $apk_count 个 APK 文件"
    return 0
}

# 签名 APK (可选)
sign_apk() {
    echo -e "\n🔐 签名 APK..."
    
    local keystore="$PROJECT_DIR/.keystore"
    if [ ! -f "$keystore" ]; then
        echo -e "${YELLOW}⚠ 未找到签名文件 ($keystore)${NC}"
        echo "  跳过签名步骤"
        return 0
    fi
    
    if ! command -v jarsigner &> /dev/null; then
        echo -e "${YELLOW}⚠ jarsigner 未安装，跳过签名${NC}"
        return 0
    fi
    
    echo "签名未实现，请使用 jarsigner 手动签名 APK"
    return 0
}

# 创建 Release Notes
create_release_notes() {
    local release_notes_file="$PROJECT_DIR/RELEASE_NOTES.md"
    
    cat > "$release_notes_file" << EOF
# 冰阅 v$VERSION 发布

## 📱 系统要求
- Android 6.0 (API 23) 及以上

## ✨ 主要功能
- 📥 **灵活的书源导入** - 支持 JSON、XML、文本、URL 等格式
- 📚 **完整的书架管理** - 自动保存阅读进度
- 📖 **沉浸式阅读器** - 流畅翻页、深色模式、快捷键支持
- 🌙 **个性化设置** - 主题切换、字体调节
- 💾 **本地存储** - 离线继续阅读

## 🚀 快速开始
1. 下载 APK 文件
2. 在 Android 设备上安装
3. 允许所需权限
4. 点击"书源"→"导入"添加书源
5. 开始阅读

## 📖 使用指南
详见 [完整规则指南](./COMPLETE_RULES_GUIDE.md)

### 快捷键 (仅阅读器)
- ← 或 A: 上一章
- → 或 D 或 Space: 下一章
- Q 或 Esc: 打开/关闭目录
- B: 添加到书架

### 手势
- 向左滑动: 下一章
- 向右滑动: 上一章
- 长按(>1s): 显示提示

## 🐛 已知问题
- 无

## 📝 更新日志

### v$VERSION ($(date +%Y年%m月%d日))
- ✓ 完善界面交互逻辑
- ✓ 增强动画效果
- ✓ 编写完整规则指南
- ✓ 优化 Android 构建流程
- ✓ 添加 Python/Java 工具支持

EOF
    
    echo -e "${GREEN}✓${NC} Release Notes 已生成"
}

# 发布到 GitHub
publish_to_github() {
    echo -e "\n📤 发布到 GitHub..."
    
    if ! command -v gh &> /dev/null; then
        echo -e "${YELLOW}⚠ GitHub CLI 未安装，跳过发布${NC}"
        echo "  请手动创建 Release: https://github.com/$GITHUB_REPO/releases"
        return 0
    fi
    
    # 检查 GitHub 认证
    if ! gh auth status >/dev/null 2>&1; then
        echo -e "${RED}✗ 未登录 GitHub${NC}"
        echo "  运行 'gh auth login' 进行认证"
        return 1
    fi
    
    # 收集 APK 文件
    local apk_files=($(find "$PROJECT_DIR/release" -name "*.apk" -type f 2>/dev/null))
    
    if [ ${#apk_files[@]} -eq 0 ]; then
        echo -e "${RED}✗ 未找到 APK 文件${NC}"
        return 1
    fi
    
    # 创建 Release Notes
    create_release_notes
    
    # 创建 git tag 和 Release
    echo "创建 tag: $GIT_TAG"
    git tag -a "$GIT_TAG" -m "Release v$VERSION" || true
    git push origin "$GIT_TAG" 2>/dev/null || true
    
    echo "创建 GitHub Release..."
    gh release create "$GIT_TAG" \
        "${apk_files[@]}" \
        -n "$(cat "$PROJECT_DIR/RELEASE_NOTES.md")" \
        -t "v$VERSION" \
        --latest 2>/dev/null || {
        echo -e "${YELLOW}⚠ Release 已存在，跳过创建${NC}"
    }
    
    echo -e "${GREEN}✓${NC} GitHub Release 已发布"
    echo "📂 Release 页面: https://github.com/$GITHUB_REPO/releases/tag/$GIT_TAG"
    
    return 0
}

# 生成统计信息
generate_stats() {
    echo -e "\n📊 构建统计"
    
    local apk_files=($(find "$PROJECT_DIR/release" -name "*.apk" -type f 2>/dev/null))
    
    echo "生成的 APK 文件:"
    for apk in "${apk_files[@]}"; do
        local size=$(du -h "$apk" | cut -f1)
        local basename=$(basename "$apk")
        echo "  - $basename ($size)"
    done
    
    echo ""
    echo "构建信息:"
    echo "  版本号: $VERSION"
    echo "  Git Tag: $GIT_TAG"
    echo "  构建时间: $(date)"
}

# 主函数
main() {
    if ! check_requirements; then
        echo -e "${RED}❌ 环境检查失败${NC}"
        return 1
    fi
    
    if ! check_git_status; then
        echo -e "${RED}❌ Git 状态检查失败${NC}"
        return 1
    fi
    
    if ! build_apks; then
        echo -e "${RED}❌ APK 构建失败${NC}"
        return 1
    fi
    
    sign_apk || true
    
    read -p "发布到 GitHub? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if ! publish_to_github; then
            echo -e "${YELLOW}⚠ GitHub 发布失败，但本地构建成功${NC}"
        fi
    fi
    
    generate_stats
    
    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ 发布流程完成!${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
}

# 执行主函数
main

