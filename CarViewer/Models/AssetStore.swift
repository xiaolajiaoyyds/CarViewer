//
//  AssetStore.swift
//  CarViewer
//
//  资源存储状态管理
//

import SwiftUI
import AppKit

/// 资源存储状态管理器
@Observable
final class AssetStore {
    // MARK: - 存储状态

    /// 底层 ThemeKit 存储对象
    private(set) var storage: TKMutableAssetStorage?

    /// 当前打开的文件 URL
    private(set) var fileURL: URL?

    /// 文件名
    var fileName: String {
        fileURL?.lastPathComponent ?? String(localized: "status.noFile")
    }

    // MARK: - 资源列表

    /// 所有资源项
    private(set) var allRenditions: [RenditionItem] = []

    /// 筛选后的资源项
    var filteredRenditions: [RenditionItem] {
        var result = allRenditions

        // 类型筛选
        if filterType != .all {
            result = result.filter { $0.type == filterType }
        }

        // 分辨率筛选
        if let scaleValue = filterScale.scaleValue {
            if scaleValue == 0 {
                // 无标识：scale == 1 且不是位图，或者是 PDF/SVG 等
                result = result.filter { !$0.hasScaleIdentifier }
            } else {
                result = result.filter { $0.scale == scaleValue }
            }
        }

        // 搜索筛选
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.elementName.lowercased().contains(query)
            }
        }

        return result
    }

    // MARK: - 选择状态

    /// 选中的资源 ID 集合
    var selectedItems: Set<RenditionItem.ID> = []

    /// 获取选中的资源项
    var selectedRenditions: [RenditionItem] {
        allRenditions.filter { selectedItems.contains($0.id) }
    }

    // MARK: - 筛选状态

    /// 搜索文本
    var searchText: String = ""

    /// 类型筛选
    var filterType: RenditionType = .all

    /// 分辨率筛选
    var filterScale: ScaleFilter = .all

    // MARK: - 视图状态

    /// 网格缩放比例 (0.5 ~ 2.0)
    var gridScale: Double = 1.0

    /// 是否显示详情面板
    var showDetail: Bool = false

    /// 是否正在加载
    private(set) var isLoading: Bool = false

    /// 加载进度 (0.0 ~ 1.0)
    private(set) var loadingProgress: Double = 0

    /// 错误信息
    var errorMessage: String?

    // MARK: - 导出状态

    /// 是否正在导出
    private(set) var isExporting: Bool = false

    /// 导出进度 (0.0 ~ 1.0)
    private(set) var exportProgress: Double = 0

    /// 导出总数
    private(set) var exportTotal: Int = 0

    /// 已导出数量
    private(set) var exportCompleted: Int = 0

    /// 是否显示导出选项面板
    var showExportOptions: Bool = false

    /// 待导出的资源项
    var pendingExportItems: [RenditionItem] = []

    /// 选择的导出分辨率
    var exportScaleOption: ExportScaleOption = .all

    // MARK: - 加载

    /// 从 URL 加载 .car 文件
    @MainActor
    func load(from url: URL) async {
        isLoading = true
        loadingProgress = 0.1
        errorMessage = nil
        allRenditions = []
        selectedItems = []

        do {
            // 加载存储
            guard let newStorage = TKMutableAssetStorage(path: url.path) else {
                throw AssetError.loadFailed
            }

            storage = newStorage
            fileURL = url
            loadingProgress = 0.2

            // 等待 ThemeKit 完成枚举（使用通知）
            await waitForStorageLoading(newStorage)
            loadingProgress = 0.5

            // 使用 allRenditions() 方法直接获取所有资源
            let allTKRenditions = newStorage.allRenditions() ?? []
            var items: [RenditionItem] = []

            let total = allTKRenditions.count
            var processed = 0

            for rendition in allTKRenditions {
                // 查找对应的 element 名称
                let elementName = findElementName(for: rendition, in: newStorage)
                let item = RenditionItem(rendition: rendition, elementName: elementName)
                items.append(item)

                processed += 1
                if processed % 100 == 0 {
                    loadingProgress = 0.5 + 0.4 * Double(processed) / Double(max(total, 1))
                }
            }

            // 按名称排序
            items.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
            allRenditions = items
            loadingProgress = 1.0

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// 等待存储加载完成
    private func waitForStorageLoading(_ storage: TKAssetStorage) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            // 使用标记防止重复 resume
            var hasResumed = false
            let lock = NSLock()

            func safeResume() {
                lock.lock()
                defer { lock.unlock() }
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume()
            }

            // 监听加载完成通知
            var observer: NSObjectProtocol?
            observer = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("TKAssetStorageDidFinishLoadingNotification"),
                object: storage,
                queue: .main
            ) { _ in
                if let obs = observer {
                    NotificationCenter.default.removeObserver(obs)
                }
                safeResume()
            }

            // 设置超时，防止通知不触发
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if let obs = observer {
                    NotificationCenter.default.removeObserver(obs)
                }
                safeResume()
            }
        }
    }

    /// 查找 rendition 所属的 element 名称
    private func findElementName(for rendition: TKRendition, in storage: TKAssetStorage) -> String {
        for element in storage.elements {
            if element.renditions.contains(rendition) {
                return element.name
            }
        }
        return "Unknown"
    }

    // MARK: - 导出

    /// 导出选中的资源
    @MainActor
    func exportSelected() {
        guard !selectedRenditions.isEmpty else { return }
        pendingExportItems = selectedRenditions
        showExportOptions = true
    }

    /// 导出所有资源
    @MainActor
    func exportAll() {
        guard !allRenditions.isEmpty else { return }
        pendingExportItems = allRenditions
        showExportOptions = true
    }

    /// 导出指定类型的资源
    @MainActor
    func exportType(_ type: RenditionType) {
        let items = allRenditions.filter { $0.type == type }
        guard !items.isEmpty else { return }
        pendingExportItems = items
        showExportOptions = true
    }

    /// 确认导出（从选项面板调用）
    @MainActor
    func confirmExport() {
        showExportOptions = false
        showExportPanel(for: pendingExportItems, scaleOption: exportScaleOption)
    }

    /// 显示导出面板
    @MainActor
    private func showExportPanel(for items: [RenditionItem], scaleOption: ExportScaleOption) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = Locale.current.language.languageCode?.identifier == "zh" ? "选择导出文件夹" : "Choose Export Folder"

        guard panel.runModal() == .OK, let directory = panel.url else { return }

        // 根据分辨率选项筛选资源
        let filteredItems = filterItemsForExport(items, scaleOption: scaleOption)
        startExport(items: filteredItems, to: directory)
    }

    /// 根据导出选项筛选资源
    private func filterItemsForExport(_ items: [RenditionItem], scaleOption: ExportScaleOption) -> [RenditionItem] {
        switch scaleOption {
        case .all:
            return items
        case .scale1x:
            return items.filter { $0.scale == 1.0 }
        case .scale2x:
            return items.filter { $0.scale == 2.0 }
        case .scale3x:
            return items.filter { $0.scale == 3.0 }
        case .scale2xAnd3x:
            return items.filter { $0.scale == 2.0 || $0.scale == 3.0 }
        case .highest:
            // 按资源名分组，每组只保留最高分辨率
            var highestByName: [String: RenditionItem] = [:]
            for item in items {
                let baseName = item.name.replacingOccurrences(of: "@2x", with: "")
                    .replacingOccurrences(of: "@3x", with: "")
                if let existing = highestByName[baseName] {
                    if item.scale > existing.scale {
                        highestByName[baseName] = item
                    }
                } else {
                    highestByName[baseName] = item
                }
            }
            return Array(highestByName.values)
        }
    }

    /// 开始导出（带进度显示）
    @MainActor
    func startExport(items: [RenditionItem], to directory: URL) {
        guard !isExporting else { return }

        isExporting = true
        exportProgress = 0
        exportTotal = items.count
        exportCompleted = 0

        Task {
            await performExport(items: items, to: directory)
        }
    }

    /// 执行导出
    @MainActor
    private func performExport(items: [RenditionItem], to directory: URL) async {
        for (index, item) in items.enumerated() {
            do {
                try await ExportService.shared.exportItem(item, to: directory)
            } catch {
                print("Export failed for \(item.name): \(error)")
            }

            exportCompleted = index + 1
            exportProgress = Double(exportCompleted) / Double(exportTotal)

            // 每导出 10 个文件暂停一下，避免系统过载
            if exportCompleted % 10 == 0 {
                try? await Task.sleep(for: .milliseconds(50))
            }
        }

        // 导出完成
        isExporting = false

        // 打开导出目录
        NSWorkspace.shared.open(directory)
    }

    // MARK: - 编辑

    /// 替换位图资源的图片
    @MainActor
    func replaceImage(for item: RenditionItem, with image: NSImage) {
        guard let bitmapRendition = item.bitmapRendition else { return }

        // 转换为 NSBitmapImageRep
        guard let tiffData = image.tiffRepresentation,
              let imageRep = NSBitmapImageRep(data: tiffData) else { return }

        bitmapRendition.image = imageRep
        item.refreshPreview()
    }

    /// 保存修改
    @MainActor
    func save() {
        storage?.write(toDiskUpdatingChangeCounts: true)
    }

    // MARK: - 统计

    /// 资源总数
    var totalCount: Int {
        allRenditions.count
    }

    /// 筛选后数量
    var filteredCount: Int {
        filteredRenditions.count
    }

    /// 选中数量
    var selectedCount: Int {
        selectedItems.count
    }

    /// 状态文本
    var statusText: String {
        if selectedCount > 0 {
            return String(localized: "status.selected \(selectedCount)")
        } else if filteredCount != totalCount {
            return String(localized: "status.filtered \(filteredCount) \(totalCount)")
        } else {
            return String(localized: "status.total \(totalCount)")
        }
    }
}

// MARK: - 错误类型

enum AssetError: LocalizedError {
    case loadFailed
    case exportFailed
    case invalidFile

    var errorDescription: String? {
        switch self {
        case .loadFailed: return String(localized: "error.loadFailed")
        case .exportFailed: return String(localized: "error.exportFailed")
        case .invalidFile: return String(localized: "error.invalidFile")
        }
    }
}
