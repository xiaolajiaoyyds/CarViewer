//
//  ExportService.swift
//  CarViewer
//
//  资源导出服务
//

import AppKit
import UniformTypeIdentifiers

/// 资源导出服务
actor ExportService {
    /// 共享实例
    static let shared = ExportService()

    private init() {}

    // MARK: - 导出方法

    /// 导出多个资源到指定目录
    func exportItems(
        _ items: [RenditionItem],
        to directory: URL,
        progress: @escaping (Double) -> Void
    ) async {
        let total = items.count
        var completed = 0

        for item in items {
            do {
                try await exportItem(item, to: directory)
            } catch {
                print("Export failed for \(item.name): \(error)")
            }

            completed += 1
            await MainActor.run {
                progress(Double(completed) / Double(total))
            }
        }

        // 导出完成后打开目录
        await MainActor.run {
            NSWorkspace.shared.open(directory)
        }
    }

    /// 导出单个资源
    func exportItem(_ item: RenditionItem, to directory: URL) async throws {
        let fileName = generateFileName(for: item)
        let fileURL = directory.appendingPathComponent(fileName)

        switch item.type {
        case .image:
            try await exportBitmap(item, to: fileURL)
        case .color:
            try await exportColor(item, to: fileURL)
        case .gradient:
            try await exportGradient(item, to: fileURL)
        case .pdf:
            try await exportPDF(item, to: fileURL)
        case .svg:
            try await exportSVG(item, to: fileURL)
        case .rawData:
            try await exportRawData(item, to: fileURL)
        default:
            // 对于未知类型，尝试导出预览图
            try await exportPreview(item, to: fileURL)
        }
    }

    // MARK: - 私有导出方法

    /// 导出位图
    private func exportBitmap(_ item: RenditionItem, to url: URL) async throws {
        guard let bitmapRendition = item.bitmapRendition,
              let imageRep = bitmapRendition.image else {
            throw AssetError.exportFailed
        }

        let pngURL = url.deletingPathExtension().appendingPathExtension("png")
        guard let pngData = imageRep.representation(using: .png, properties: [:]) else {
            throw AssetError.exportFailed
        }

        try pngData.write(to: pngURL)
    }

    /// 导出颜色（作为 1x1 PNG）
    private func exportColor(_ item: RenditionItem, to url: URL) async throws {
        guard let colorRendition = item.colorRendition,
              let color = colorRendition.color else {
            throw AssetError.exportFailed
        }

        // 创建 1x1 的颜色图片
        let image = NSImage(size: NSSize(width: 64, height: 64))
        image.lockFocus()
        color.setFill()
        NSRect(x: 0, y: 0, width: 64, height: 64).fill()
        image.unlockFocus()

        guard let tiffData = image.tiffRepresentation,
              let imageRep = NSBitmapImageRep(data: tiffData),
              let pngData = imageRep.representation(using: .png, properties: [:]) else {
            throw AssetError.exportFailed
        }

        let pngURL = url.deletingPathExtension().appendingPathExtension("png")
        try pngData.write(to: pngURL)
    }

    /// 导出渐变（作为预览图）
    private func exportGradient(_ item: RenditionItem, to url: URL) async throws {
        try await exportPreview(item, to: url)
    }

    /// 导出 PDF
    private func exportPDF(_ item: RenditionItem, to url: URL) async throws {
        guard let pdfRendition = item.rendition as? TKPDFRendition,
              let rawData = pdfRendition.rawData else {
            throw AssetError.exportFailed
        }

        let pdfURL = url.deletingPathExtension().appendingPathExtension("pdf")
        try rawData.write(to: pdfURL)
    }

    /// 导出 SVG
    private func exportSVG(_ item: RenditionItem, to url: URL) async throws {
        guard let svgRendition = item.rendition as? TKSVGRendition,
              let rawData = svgRendition.rawData else {
            throw AssetError.exportFailed
        }

        // SVG 数据可能有头部偏移
        let svgURL = url.deletingPathExtension().appendingPathExtension("svg")
        try rawData.write(to: svgURL)
    }

    /// 导出原始数据
    private func exportRawData(_ item: RenditionItem, to url: URL) async throws {
        guard let rawDataRendition = item.rendition as? TKRawDataRendition,
              let rawData = rawDataRendition.rawData else {
            throw AssetError.exportFailed
        }

        try rawData.write(to: url)
    }

    /// 导出预览图
    private func exportPreview(_ item: RenditionItem, to url: URL) async throws {
        guard let previewImage = item.previewImage else {
            throw AssetError.exportFailed
        }

        guard let tiffData = previewImage.tiffRepresentation,
              let imageRep = NSBitmapImageRep(data: tiffData),
              let pngData = imageRep.representation(using: .png, properties: [:]) else {
            throw AssetError.exportFailed
        }

        let pngURL = url.deletingPathExtension().appendingPathExtension("png")
        try pngData.write(to: pngURL)
    }

    // MARK: - 文件名生成

    /// 生成导出文件名
    private func generateFileName(for item: RenditionItem) -> String {
        var name = item.name.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")

        // 添加缩放后缀
        if item.scale > 1 {
            name += "@\(Int(item.scale))x"
        }

        // 添加扩展名
        switch item.type {
        case .pdf:
            return name + ".pdf"
        case .svg:
            return name + ".svg"
        default:
            return name + ".png"
        }
    }
}
