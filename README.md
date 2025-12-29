# CarViewer

<p align="center">
  <img src="Docs/img/logo.png" width="128" height="128" alt="CarViewer Logo">
</p>

<p align="center">
  <strong>一款现代化的 Assets.car 资源查看器</strong><br>
  A Modern Assets.car Resource Viewer
</p>

<p align="center">
  中文 | <a href="README_EN.md">English</a>
</p>

<p align="center">
  <a href="#功能特性">功能特性</a> •
  <a href="#安装">安装</a> •
  <a href="#使用说明">使用说明</a> •
  <a href="#项目架构">项目架构</a> •
  <a href="#致谢">致谢</a> •
  <a href="#许可证">许可证</a>
</p>

---

## 功能特性

- **资源预览** - 支持预览图片、颜色、渐变、PDF、SVG 等多种资源类型
- **分类筛选** - 按资源类型快速筛选（图片、颜色、渐变、特效等）
- **分辨率筛选** - 支持按 @1x、@2x、@3x 或无标识筛选
- **搜索功能** - 快速搜索资源名称
- **批量导出** - 支持导出选中或全部资源为 PNG 格式
- **智能导出选项** - 可选择导出特定分辨率（仅 @2x、仅 @3x、最高分辨率等）
- **现代化界面** - 基于 SwiftUI 构建，支持深色模式
- **中英文支持** - 自动适配系统语言

## 系统要求

- macOS 14.0 (Sonoma) 或更高版本
- Apple Silicon 或 Intel Mac

## 安装

### 下载发行版

前往 [Releases](https://github.com/xiaolajiaoyyds/CarViewer/releases) 页面下载最新版本的 `.dmg` 或 `.zip` 文件。

### 从源码构建

```bash
# 克隆仓库
git clone https://github.com/xiaolajiaoyyds/CarViewer.git
cd CarViewer

# 使用 Xcode 打开项目
open CarViewer.xcodeproj

# 或使用命令行构建
xcodebuild -scheme CarViewer -configuration Release build
```

## 使用说明

### 打开文件

1. 启动 CarViewer
2. 使用菜单 `文件 > 打开` 或快捷键 `⌘O` 选择 `.car` 文件
3. 常见的 `.car` 文件位置：
   - 应用包内：`/Applications/YourApp.app/Contents/Resources/Assets.car`
   - iOS 模拟器：`~/Library/Developer/CoreSimulator/...`
   - 系统资源：`/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Assets.car`

### 浏览资源

- **侧边栏**：按类型分类查看资源
- **网格视图**：预览所有资源缩略图
- **详情面板**：点击资源查看详细信息

### 筛选资源

- **类型筛选**：在侧边栏选择资源类型
- **分辨率筛选**：使用顶部工具栏的分辨率选择器
- **搜索**：在搜索框输入资源名称

### 导出资源

1. **导出选中**：选择资源后，使用 `⇧⌘E` 或右键菜单导出
2. **导出全部**：使用 `⌥⌘E` 或侧边栏底部的「导出全部资源」按钮
3. **导出特定类型**：在侧边栏右键点击类型，选择「导出全部 XXX」

### 导出选项

导出时可选择分辨率：
- **全部分辨率**：导出所有版本
- **仅 @1x / @2x / @3x**：导出指定分辨率
- **@2x 和 @3x**：推荐用于现代 iOS/macOS 项目
- **仅最高分辨率**：每个资源只导出最高分辨率版本

## 项目架构

```
CarViewer/
├── App/
│   └── CarViewerApp.swift          # 应用入口、菜单、关于窗口
├── Models/
│   ├── AssetStore.swift            # 状态管理（@Observable）
│   ├── RenditionItem.swift         # 资源项包装类
│   ├── RenditionType.swift         # 资源类型枚举
│   └── ScaleFilter.swift           # 分辨率筛选枚举
├── Views/
│   ├── MainView.swift              # 主界面布局
│   ├── SidebarView.swift           # 侧边栏
│   ├── AssetGridView.swift         # 资源网格
│   ├── AssetCell.swift             # 资源单元格
│   ├── DetailPanel.swift           # 详情面板
│   └── ExportOptionsSheet.swift    # 导出选项弹窗
├── Services/
│   └── ExportService.swift         # 导出服务
├── Resources/
│   ├── Assets.xcassets             # 应用图标等
│   ├── Localizable.strings         # 国际化字符串
│   ├── logo.png                    # 应用 Logo
│   └── zanshangma.png              # 赞赏码
└── Supporting Files/
    ├── Info.plist
    ├── CarViewer.entitlements
    └── CarViewer-Bridging-Header.h # Objective-C 桥接头
```

### 技术栈

- **SwiftUI** - 现代化 UI 框架
- **@Observable** - Swift 5.9 宏，用于状态管理
- **ThemeKit** - 用于解析 .car 文件的框架（基于私有 CoreUI 框架）

## 致谢

本项目的核心解析能力基于 [ThemeEngine](https://github.com/alexzielenski/ThemeEngine) 项目。

特别感谢：

- **[Alex Zielenski](https://github.com/alexzielenski)** - ThemeEngine 项目作者，提供了 .car 文件解析的核心实现
- **ThemeKit** - 对 Apple 私有 CoreUI 框架的 Objective-C 封装

ThemeEngine 是一款功能强大的 macOS 应用，不仅可以查看还可以编辑 .car 文件。本项目（CarViewer）专注于提供更现代化的只读浏览体验。

## 赞赏支持

如果觉得这个项目对你有帮助，欢迎请作者喝杯咖啡 :coffee:

<p align="center">
  <img src="Docs/img/zanshangma.png" width="200" alt="微信赞赏码">
  <br>
  <em>微信扫码</em>
</p>

## 联系方式

- **Email**: xiaolajiaoyyds@gmail.com
- **GitHub**: [@xiaolajiaoyyds](https://github.com/xiaolajiaoyyds)
- **Issues**: [提交问题](https://github.com/xiaolajiaoyyds/CarViewer/issues)

## 许可证

本项目基于 [BSD-2-Clause License](LICENSE) 开源。

```
Copyright (c) 2026, xiaolajiaoyyds
All rights reserved.
```

---

<p align="center">
  Made with :heart: by xiaolajiaoyyds
</p>
