#!/bin/bash

# 冰阅 APP GitHub Releases 发布脚本
# 自动创建 GitHub Release 并上传 APK 文件

set -e

PROJECT_NAME="bingyuege-app"
REPO_OWNER="TYQ2005"
REPO_NAME="bingyuege-app"
VERSION="${1:-v1.0.0}"

echo "📤 冰阅 APP GitHub Releases 发布工具"
echo "======================================="

# 检查必要的命令
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ 命令未找到: $1"
        echo "请安装后重试"
        exit 1
    fi
}

check_command "git"
check_command "curl"

# 检查 GitHub 令牌
if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ 环境变量 GITHUB_TOKEN 未设置"
    echo ""
    echo "请设置 GitHub 令牌："
    echo "  export GITHUB_TOKEN=your_token_here"
    echo ""
    echo "获取令牌：https://github.com/settings/tokens"
    echo "  需要权限: repo, read:repo_hook"
    exit 1
fi

# 验证 GitHub 令牌
echo "🔐 验证 GitHub 令牌..."
GITHUB_USER=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    https://api.github.com/user | grep -o '"login":"[^"]*"' | cut -d'"' -f4)

if [ -z "$GITHUB_USER" ]; then
    echo "❌ GitHub 令牌无效"
    exit 1
fi
echo "✅ 已验证为：$GITHUB_USER"

# 检查 APK 文件
APK_UNSIGNED="platforms/android/app/build/outputs/apk/release/app-release-unsigned.apk"
APK_SIGNED="platforms/android/app/build/outputs/apk/release/app-release.apk"

if [ -f "$APK_SIGNED" ]; then
    APK_FILE="$APK_SIGNED"
    echo "✅ 已签名 APK: $APK_FILE"
elif [ -f "$APK_UNSIGNED" ]; then
    APK_FILE="$APK_UNSIGNED"
    echo "⚠️  使用未签名 APK（不推荐用于生产）"
    echo "   位置: $APK_FILE"
else
    echo "❌ APK 文件未找到"
    echo "   预期位置:"
    echo "     - $APK_SIGNED"
    echo "     - $APK_UNSIGNED"
    echo ""
    echo "请先执行构建:"
    echo "  npm run build  # 或"
    echo "  ./build.sh"
    exit 1
fi

# 获取 APK 信息
APK_SIZE=$(du -h "$APK_FILE" | cut -f1)
APK_MD5=$(md5sum "$APK_FILE" | cut -d' ' -f1)

echo ""
echo "📦 APK 信息"
echo "------"
echo "文件: $(basename $APK_FILE)"
echo "大小: $APK_SIZE"
echo "MD5:  $APK_MD5"

# 检查 Release 是否已存在
echo ""
echo "🔍 检查 Release 状态..."
RELEASE_INFO=$(curl -s \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/tags/$VERSION")

if echo "$RELEASE_INFO" | grep -q '"tag_name"'; then
    echo "⚠️  Release $VERSION 已存在"
    echo ""
    
    # 提示用户选择操作
    read -p "是否覆盖现有 Release? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "取消发布"
        exit 0
    fi
    
    # 删除现有 Release
    echo "删除现有 Release..."
    RELEASE_ID=$(echo "$RELEASE_INFO" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    curl -s -X DELETE \
        -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/$RELEASE_ID"
    echo "✅ 已删除"
else
    echo "✅ Release $VERSION 不存在，准备创建"
fi

# 创建 Release
echo ""
echo "📝 创建 Release..."

RELEASE_BODY="# 冰阅 v1.0.0

## 功能特性 ✨

- ✅ 支持多种格式书源导入（JSON/XML/文本/URL）
- ✅ 完整的书籍管理和阅读功能
- ✅ 夜间/白天主题切换
- ✅ 阅读进度自动保存
- ✅ 章节导航和目录快速定位
- ✅ 书架管理和同步

## 安装方式 📱

1. 下载 APK 文件
2. 在 Android 设备上安装
3. 允许必要的权限
4. 开始使用

## 技术信息 🔧

| 项目 | 值 |
|------|-----|
| 应用包名 | com.bingyuege.app |
| 最低 Android 版本 | 6.0 (API 23) |
| 目标 Android 版本 | 12+ |
| APK 大小 | $APK_SIZE |
| MD5 哈希 | $APK_MD5 |

## 更新日志 📋

详见 [CHANGELOG.md](CHANGELOG.md)

## 报告问题 🐛

如发现问题，请在 [Issues](https://github.com/$REPO_OWNER/$REPO_NAME/issues) 提交反馈。
"

RELEASE_JSON=$(cat <<EOF
{
  "tag_name": "$VERSION",
  "name": "冰阅 $VERSION",
  "body": $(echo "$RELEASE_BODY" | jq -Rs .),
  "draft": false,
  "prerelease": false
}
EOF
)

RELEASE_RESPONSE=$(curl -s -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -d "$RELEASE_JSON" \
    "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases")

if echo "$RELEASE_RESPONSE" | grep -q '"id"'; then
    RELEASE_ID=$(echo "$RELEASE_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    echo "✅ Release 已创建: $VERSION"
else
    echo "❌ Release 创建失败"
    echo "$RELEASE_RESPONSE" | jq .
    exit 1
fi

# 上传 APK 文件
echo ""
echo "⬆️  上传 APK 文件..."

UPLOAD_URL="https://uploads.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/$RELEASE_ID/assets?name=$(basename $APK_FILE)"

curl -s -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Content-Type: application/vnd.android.package-archive" \
    --data-binary @"$APK_FILE" \
    "$UPLOAD_URL" > /dev/null

echo "✅ APK 文件已上传"

# 最终信息
echo ""
echo "✅ 发布完成！"
echo "======================================="
echo "Release URL: https://github.com/$REPO_OWNER/$REPO_NAME/releases/tag/$VERSION"
echo ""
echo "用户可以通过以下方式获取 APK:"
echo "1. 访问上述 URL"
echo "2. 点击 APK 文件进行下载"
echo "3. 在 Android 设备上安装"
