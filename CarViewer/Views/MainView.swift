//
//  MainView.swift
//  CarViewer
//
//  主界面视图
//

import SwiftUI

struct MainView: View {
    @Environment(AssetStore.self) private var store

    var body: some View {
        @Bindable var store = store

        NavigationSplitView {
            SidebarView()
        } detail: {
            VStack(spacing: 0) {
                // 工具栏
                ToolbarView()

                Divider()

                // 主内容区
                if store.isLoading {
                    LoadingView(progress: store.loadingProgress)
                } else if store.allRenditions.isEmpty {
                    EmptyStateView()
                } else {
                    AssetGridView()
                }

                Divider()

                // 状态栏
                StatusBarView()
            }
        }
        .navigationTitle(store.fileName)
        .inspector(isPresented: $store.showDetail) {
            if let selectedItem = store.selectedRenditions.first {
                DetailPanel(item: selectedItem)
            } else {
                Text(String(localized: "detail.noSelection"))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
        .alert(
            String(localized: "error.title"),
            isPresented: .init(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )
        ) {
            Button(String(localized: "button.ok"), role: .cancel) {}
        } message: {
            Text(store.errorMessage ?? "")
        }
        // 导出进度条 overlay
        .overlay {
            if store.isExporting {
                ExportProgressOverlay(
                    progress: store.exportProgress,
                    completed: store.exportCompleted,
                    total: store.exportTotal
                )
            }
        }
        // 导出选项面板
        .sheet(isPresented: $store.showExportOptions) {
            ExportOptionsSheet()
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        _ = provider.loadObject(ofClass: URL.self) { url, error in
            if let url = url, url.pathExtension.lowercased() == "car" {
                Task { @MainActor in
                    await store.load(from: url)
                }
            }
        }
        return true
    }
}

// MARK: - 工具栏视图
struct ToolbarView: View {
    @Environment(AssetStore.self) private var store

    var body: some View {
        @Bindable var store = store

        HStack(spacing: 16) {
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(String(localized: "search.placeholder"), text: $store.searchText)
                    .textFieldStyle(.plain)
                if !store.searchText.isEmpty {
                    Button {
                        store.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: 300)

            Spacer()

            // 类型筛选
            Picker(String(localized: "filter.type"), selection: $store.filterType) {
                ForEach(RenditionType.allCases) { type in
                    Label(type.localizedName, systemImage: type.systemImage)
                        .tag(type)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 140)

            // 分辨率筛选
            Picker("", selection: $store.filterScale) {
                ForEach(ScaleFilter.allCases) { scale in
                    Label(scale.localizedName, systemImage: scale.systemImage)
                        .tag(scale)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120)

            // 缩放滑块
            HStack(spacing: 8) {
                Image(systemName: "minus.magnifyingglass")
                    .foregroundStyle(.secondary)
                Slider(value: $store.gridScale, in: 0.5...2.0, step: 0.25)
                    .frame(width: 100)
                Image(systemName: "plus.magnifyingglass")
                    .foregroundStyle(.secondary)
            }

            // 详情面板切换
            Toggle(isOn: $store.showDetail) {
                Image(systemName: "sidebar.trailing")
            }
            .toggleStyle(.button)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

// MARK: - 状态栏视图
struct StatusBarView: View {
    @Environment(AssetStore.self) private var store

    var body: some View {
        HStack {
            Text(store.statusText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            if !store.selectedItems.isEmpty {
                Button(String(localized: "export.selected")) {
                    store.exportSelected()
                }
                .buttonStyle(.borderless)
            }

            if !store.allRenditions.isEmpty {
                Button(String(localized: "export.all")) {
                    store.exportAll()
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.bar)
    }
}

// MARK: - 加载视图
struct LoadingView: View {
    let progress: Double

    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(width: 200)

            Text(String(localized: "loading.message"))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 空状态视图
struct EmptyStateView: View {
    @Environment(AssetStore.self) private var store

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text(String(localized: "empty.title"))
                    .font(.title2)
                    .fontWeight(.medium)

                Text(String(localized: "empty.subtitle"))
                    .foregroundStyle(.secondary)
            }

            Button(String(localized: "empty.openButton")) {
                openFile()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

// MARK: - 导出进度条 Overlay
struct ExportProgressOverlay: View {
    let progress: Double
    let completed: Int
    let total: Int

    private var isChinese: Bool {
        Locale.current.language.languageCode?.identifier == "zh"
    }

    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            // 进度卡片
            VStack(spacing: 16) {
                Text(isChinese ? "正在导出..." : "Exporting...")
                    .font(.headline)

                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(width: 280)

                Text("\(completed) / \(total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(32)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            }
        }
        .animation(.easeInOut, value: progress)
    }
}

#Preview {
    MainView()
        .environment(AssetStore())
        .frame(width: 1000, height: 700)
}
