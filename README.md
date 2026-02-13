# 冰阅阁 (bingyuege-app)

[![构建状态](https://github.com/TYQ2005/bingyuege-app/actions/workflows/build-apk.yml/badge.svg)](https://github.com/TYQ2005/bingyuege-app/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Release](https://img.shields.io/github/v/release/TYQ2005/bingyuege-app)](https://github.com/TYQ2005/bingyuege-app/releases)

一款**多功能阅读APP**，支持灵活的书源导入、丰富的交互阅读功能，为书籍爱好者提供优秀的阅读体验。

## ✨ 功能特性

- 📥 **四种书源导入格式**
  - JSON 格式数据
  - XML 格式数据
  - 文本列表 (名称|URL)
  - 远程 URL 导入

- 📚 **完整的书架管理**
  - 自动保存已添加的书籍
  - 记录阅读进度
  - 快速访问最近阅读
  - 批量管理书籍

- 📖 **沉浸式阅读体验**
  - 清晰的章节导航
  - 快速目录定位
  - 流畅的翻页效果
  - 自动记忆阅读位置

- 🌙 **个性化设置**
  - 夜间/白天主题切换
  - 字体大小调节
  - 行间距设置
  - 深色模式支持

- 💾 **数据持久化**
  - 本地存储书源数据
  - 自动保存阅读进度
  - 离线继续阅读

## 🚀 快速开始

### 下载 APK

访问 [GitHub Releases](https://github.com/TYQ2005/bingyuege-app/releases) 下载最新版本的 APK 文件。

### 安装步骤

1. 在 Android 设备上启用"未知来源"应用安装
2. 下载 `bingyuege-app-release.apk` 文件
3. 点击安装
4. 允许所需权限
5. 打开应用开始使用

### 系统要求

- **Android 版本**: 6.0 (API 23) 及以上
- **存储空间**: 至少 50 MB
- **内存**: 至少 512 MB
- **网络**: WiFi 或移动数据用于加载书源

## 📖 使用指南

详见 [IMPORT_GUIDE.md](IMPORT_GUIDE.md) - 完整的书源导入和使用指南

### 基本操作

1. **添加书源**
   - 点击"书源"tab
   - 选择"导入"或"新增"
   - 填入书源信息
   - 点击"保存"

2. **浏览书籍**
   - 点击书源进入书籍列表
   - 选择感兴趣的书籍
   - 点击开始阅读

3. **管理书架**
   - 阅读时点击"加书架"
   - 进度自动保存
   - 从书架快速回到上次位置

4. **个性化设置**
   - 在"更多"页面切换夜间模式
   - 清除缓存释放存储空间

## 🔨 构建和开发

### 环境要求

- Node.js ≥ 16.0
- npm ≥ 8.0
- Java JDK ≥ 11
- Android SDK (API 30+)
- Cordova CLI ≥ 12.0

### 本地构建

```bash
# 1. 克隆项目
git clone https://github.com/TYQ2005/bingyuege-app.git
cd bingyuege-app

# 2. 安装依赖
npm install

# 3. 构建 APK（Linux/macOS）
chmod +x build.sh
./build.sh

# 3. 构建 APK（Windows）
build.bat
```

详见 [BUILD_GUIDE.md](BUILD_GUIDE.md) - 完整的构建和发布指南

## 📦 发布流程

### 创建新版本

```bash
# 赋予执行权限（仅需一次）
chmod +x release.sh

# 执行发布
./release.sh
```

### 自动化构建

项目使用 GitHub Actions 自动构建 APK，在以下情况下触发：

- 推送到 main 分支
- 创建 v* 标签
- Pull Request 到 main 分支

构建完成后自动上传到 Releases。

## 📁 项目结构

```
bingyuege-app/
├── www/                    # Web应用源代码
│   └── index.html         # 主应用文件
├── config.xml             # Cordova配置
├── package.json           # 项目依赖配置
├── build.sh              # Linux/macOS 构建脚本
├── build.bat             # Windows 构建脚本
├── release.sh            # GitHub 发布脚本
├── BUILD_GUIDE.md        # 构建完整指南
├── IMPORT_GUIDE.md       # 书源导入指南
└── .github/workflows/
    └── build-apk.yml     # GitHub Actions 工作流
```

## 👥 开发团队

| 角色 | 成员 |
|------|------|
| 核心开发 | 冰郁泪 |
| UI 设计 | 晴宝 |
| 产品经理 | 叶青云 |
| 后端开发 | 枫叶 |

## 📧 联系方式

- **团队邮箱**: [catgopii@gmail.com](mailto:catgopii@gmail.com)
- **项目主页**: https://github.com/TYQ2005/bingyuege-app
- **问题反馈**: https://github.com/TYQ2005/bingyuege-app/issues

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

### 报告问题

1. 检查是否已有相同 Issue
2. 提供详细的问题描述
3. 包含错误日志或截图

### 提交代码

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 🎯 路线图

- [ ] 支持更多书源格式
- [ ] 添加搜索功能
- [ ] 支持书签和笔记
- [ ] 字体定制
- [ ] 云同步阅读进度
- [ ] 离线书籍下载

## 📚 相关资源

- [Cordova 文档](https://cordova.apache.org/)
- [Android 开发文档](https://developer.android.com/)
- [GitHub 流程](https://guides.github.com/introduction/flow/)

## 🙏 致谢

感谢所有为这个项目做出贡献的人，以及使用和支持我们的用户！

---

**最后更新**: 2026-02-13  
**最新版本**: v1.0.0
