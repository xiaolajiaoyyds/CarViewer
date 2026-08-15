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

        // 文件夹筛选
        if let folder = filterFolder {
            result = result.filter { $0.elementName == folder }
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

    /// 文件夹筛选（nil 表示不筛选）
    var filterFolder: String?

    // MARK: - 文件夹列表

    /// 所有文件夹名称（按字母排序，去重）
    var allFolders: [String] {
        let folders = Set(allRenditions.map { $0.elementName })
        return folders.sorted { $0.localizedCompare($1) == .orderedAscending }
    }

    /// 是否展开文件夹列表
    var isFoldersExpanded: Bool = false

    /// 文件夹搜索文本
    var folderSearchText: String = ""

    /// 筛选后的文件夹列表
    var filteredFolders: [String] {
        if folderSearchText.isEmpty {
            return allFolders
        }
        let query = folderSearchText.lowercased()
        return allFolders.filter { $0.lowercased().contains(query) }
    }

    /// 是否展开分类列表
    var isCategoriesExpanded: Bool = true

    /// 选中的文件夹集合（用于多选导出）
    var selectedFolders: Set<String> = []

    /// 切换文件夹选中状态
    @MainActor
    func toggleFolderSelection(_ folder: String) {
        if selectedFolders.contains(folder) {
            selectedFolders.remove(folder)
        } else {
            selectedFolders.insert(folder)
        }
    }

    /// 清除文件夹多选
    @MainActor
    func clearFolderSelection() {
        selectedFolders.removeAll()
    }

    /// 全选文件夹
    @MainActor
    func selectAllFolders() {
        selectedFolders = Set(filteredFolders)
    }

    /// 反选文件夹
    @MainActor
    func invertFolderSelection() {
        let allSet = Set(filteredFolders)
        selectedFolders = allSet.subtracting(selectedFolders)
    }

    /// 导出选中的多个文件夹（保留路径结构）
    @MainActor
    func exportSelectedFolders() {
        guard !selectedFolders.isEmpty else { return }

        // 收集选中文件夹的所有资源
        let items = allRenditions.filter { selectedFolders.contains($0.elementName) }
        guard !items.isEmpty else { return }

        // 使用特殊标记表示需要按文件夹路径导出
        pendingExportItems = items
        pendingExportWithFolderStructure = true
        showExportOptions = true
    }

    /// 是否按文件夹结构导出
    var pendingExportWithFolderStructure: Bool = false

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

    /// 选择的导出分辨率（支持多选）
    var exportScaleOptions: Set<ExportScaleOption> = [.all]

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

    /// 导出指定文件夹的资源
    @MainActor
    func exportFolder(_ folder: String) {
        let items = allRenditions.filter { $0.elementName == folder }
        guard !items.isEmpty else { return }
        pendingExportItems = items
        showExportOptions = true
    }

    /// 清除文件夹筛选
    @MainActor
    func clearFolderFilter() {
        filterFolder = nil
    }

    /// 确认导出（从选项面板调用）
    @MainActor
    func confirmExport() {
        showExportOptions = false
        let withFolderStructure = pendingExportWithFolderStructure
        pendingExportWithFolderStructure = false
        showExportPanel(for: pendingExportItems, scaleOptions: exportScaleOptions, withFolderStructure: withFolderStructure)
    }

    /// 显示导出面板
    @MainActor
    private func showExportPanel(for items: [RenditionItem], scaleOptions: Set<ExportScaleOption>, withFolderStructure: Bool = false) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = Locale.current.language.languageCode?.identifier == "zh" ? "选择导出文件夹" : "Choose Export Folder"

        guard panel.runModal() == .OK, let directory = panel.url else { return }

        // 为每种选中的分辨率创建子目录并导出
        Task {
            if withFolderStructure {
                await performFolderStructureExport(items: items, to: directory, scaleOptions: scaleOptions)
            } else {
                await performMultiScaleExport(items: items, to: directory, scaleOptions: scaleOptions)
            }
        }
    }

    /// 按文件夹结构导出（保留 elementName 路径）
    @MainActor
    private func performFolderStructureExport(items: [RenditionItem], to directory: URL, scaleOptions: Set<ExportScaleOption>) async {
        var allItemsToExport: [(item: RenditionItem, directory: URL)] = []

        // 按 elementName 分组
        let groupedItems = Dictionary(grouping: items) { $0.elementName }

        for option in scaleOptions.sorted(by: { $0.rawValue < $1.rawValue }) {
            for (folderName, folderItems) in groupedItems {
                let filteredItems = filterItemsForExport(folderItems, scaleOption: option)
                guard !filteredItems.isEmpty else { continue }

                // 构建目录路径：基础目录 / [分辨率子目录] / 文件夹名
                var targetDir = directory
                if scaleOptions.count > 1 {
                    targetDir = targetDir.appendingPathComponent(option.directoryName)
                }
                targetDir = targetDir.appendingPathComponent(folderName)

                do {
                    try FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)
                } catch {
                    print("Failed to create directory \(folderName): \(error)")
                    continue
                }

                for item in filteredItems {
                    allItemsToExport.append((item, targetDir))
                }
            }
        }

        guard !allItemsToExport.isEmpty else { return }

        // 开始导出
        isExporting = true
        exportProgress = 0
        exportTotal = allItemsToExport.count
        exportCompleted = 0

        for (index, (item, targetDir)) in allItemsToExport.enumerated() {
            do {
                try await ExportService.shared.exportItem(item, to: targetDir)
            } catch {
                print("Export failed for \(item.name): \(error)")
            }

            exportCompleted = index + 1
            exportProgress = Double(exportCompleted) / Double(exportTotal)

            if exportCompleted % 10 == 0 {
                try? await Task.sleep(for: .milliseconds(50))
            }
        }

        isExporting = false
        selectedFolders.removeAll()
        NSWorkspace.shared.open(directory)
    }

    /// 执行多分辨率导出（每种分辨率导出到单独子目录）
    @MainActor
    private func performMultiScaleExport(items: [RenditionItem], to directory: URL, scaleOptions: Set<ExportScaleOption>) async {
        // 如果只选了一个选项，直接导出到根目录
        if scaleOptions.count == 1, let option = scaleOptions.first {
            let filteredItems = filterItemsForExport(items, scaleOption: option)
            startExport(items: filteredItems, to: directory)
            return
        }

        // 多选情况：每种分辨率导出到单独子目录
        var allItemsToExport: [(item: RenditionItem, directory: URL)] = []

        for option in scaleOptions.sorted(by: { $0.rawValue < $1.rawValue }) {
            let filteredItems = filterItemsForExport(items, scaleOption: option)
            guard !filteredItems.isEmpty else { continue }

            // 创建子目录
            let subDirName = option.directoryName
            let subDir = directory.appendingPathComponent(subDirName)

            do {
                try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
            } catch {
                print("Failed to create directory \(subDirName): \(error)")
                continue
            }

            for item in filteredItems {
                allItemsToExport.append((item, subDir))
            }
        }

        guard !allItemsToExport.isEmpty else { return }

        // 开始导出
        isExporting = true
        exportProgress = 0
        exportTotal = allItemsToExport.count
        exportCompleted = 0

        for (index, (item, subDir)) in allItemsToExport.enumerated() {
            do {
                try await ExportService.shared.exportItem(item, to: subDir)
            } catch {
                print("Export failed for \(item.name): \(error)")
            }

            exportCompleted = index + 1
            exportProgress = Double(exportCompleted) / Double(exportTotal)

            if exportCompleted % 10 == 0 {
                try? await Task.sleep(for: .milliseconds(50))
            }
        }

        isExporting = false
        NSWorkspace.shared.open(directory)
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
        save()
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
