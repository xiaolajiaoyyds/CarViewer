//
//  CarViewerApp.swift
//  CarViewer
//
//  现代化的 Assets.car 资源查看器
//

import SwiftUI

@main
struct CarViewerApp: App {
    @State private var store = AssetStore()
    @State private var showAbout = false

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(store)
                .sheet(isPresented: $showAbout) {
                    AboutView()
                }
        }
        .commands {
            // 替换关于菜单
            CommandGroup(replacing: .appInfo) {
                Button("关于 CarViewer") {
                    showAbout = true
                }
            }

            CommandGroup(replacing: .newItem) {
                Button(String(localized: "menu.open")) {
                    openFile()
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandGroup(after: .importExport) {
                Button(String(localized: "menu.exportSelected")) {
                    store.exportSelected()
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(store.selectedItems.isEmpty)

                Button(String(localized: "menu.exportAll")) {
                    store.exportAll()
                }
                .keyboardShortcut("e", modifiers: [.command, .option])
                .disabled(store.allRenditions.isEmpty)
            }

            // 帮助菜单
            CommandGroup(replacing: .help) {
                Button("CarViewer 帮助") {
                    if let url = URL(string: "https://github.com/xiaolajiaoyyds/CarViewer#readme") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .keyboardShortcut("?", modifiers: .command)

                Divider()

                Button("访问 GitHub 仓库") {
                    if let url = URL(string: "https://github.com/xiaolajiaoyyds/CarViewer") {
                        NSWorkspace.shared.open(url)
                    }
                }

                Button("报告问题") {
                    if let url = URL(string: "https://github.com/xiaolajiaoyyds/CarViewer/issues") {
                        NSWorkspace.shared.open(url)
                    }
                }

                Divider()

                Button("联系作者") {
                    if let url = URL(string: "mailto:xiaolajiaoyyds@gmail.com") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }

        Settings {
            SettingsView()
        }
    }

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "car")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            Task {
                await store.load(from: url)
            }
        }
    }
}

// MARK: - 关于视图
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var isChinese: Bool {
        Locale.current.language.languageCode?.identifier == "zh"
    }

    var body: some View {
        VStack(spacing: 20) {
            // Logo 区域
            if let image = NSImage(contentsOfFile: Bundle.main.resourcePath! + "/logo.png") {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                // 备用 Logo
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: "car.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.white)
                }
            }

            // 应用名称和版本
            VStack(spacing: 4) {
                Text("CarViewer")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 描述
            Text(isChinese
                 ? "一款现代化的 Assets.car 资源查看器\n支持预览、筛选、导出各类资源"
                 : "A modern Assets.car resource viewer\nSupports preview, filter, and export")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Divider()

            // 链接区域
            VStack(spacing: 12) {
                Link(destination: URL(string: "https://github.com/xiaolajiaoyyds/CarViewer")!) {
                    HStack {
                        Image(systemName: "link")
                        Text("GitHub")
                    }
                }

                Link(destination: URL(string: "mailto:xiaolajiaoyyds@gmail.com")!) {
                    HStack {
                        Image(systemName: "envelope")
                        Text("xiaolajiaoyyds@gmail.com")
                    }
                }
            }
            .font(.callout)

            Divider()

            // 版权信息
            Text("© 2026 xiaolajiaoyyds. MIT License.")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            // 关闭按钮
            Button(isChinese ? "关闭" : "Close") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding(30)
        .frame(width: 360)
    }
}

// MARK: - 设置视图
struct SettingsView: View {
    private var isChinese: Bool {
        Locale.current.language.languageCode?.identifier == "zh"
    }

    var body: some View {
        Form {
            Section(isChinese ? "通用" : "General") {
                Text(isChinese ? "暂无可配置选项" : "No settings available yet")
                    .foregroundStyle(.secondary)
            }

            Section(isChinese ? "关于" : "About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("GitHub", value: "xiaolajiaoyyds/CarViewer")
                LabeledContent(isChinese ? "作者" : "Author", value: "xiaolajiaoyyds")
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 450, height: 250)
    }
}
