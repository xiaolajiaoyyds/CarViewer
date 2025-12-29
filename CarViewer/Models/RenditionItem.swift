//
//  RenditionItem.swift
//  CarViewer
//
//  TKRendition 的 Swift 包装，适配 SwiftUI
//

import SwiftUI
import AppKit

/// 资源项包装类，将 TKRendition 适配为 SwiftUI 可用的 Identifiable 对象
@Observable
final class RenditionItem: Identifiable, Hashable {
    /// 唯一标识符，使用 rendition 的 hash
    let id: String

    /// 底层 ThemeKit 渲染对象
    let rendition: TKRendition

    /// 所属元素名称
    let elementName: String

    /// 缓存的预览图
    private var _cachedPreview: NSImage?

    // MARK: - 初始化

    init(rendition: TKRendition, elementName: String) {
        self.rendition = rendition
        self.elementName = elementName
        // 使用 UUID 避免 renditionHash() 性能问题
        self.id = UUID().uuidString
    }

    // MARK: - 属性

    /// 资源名称
    var name: String {
        rendition.name ?? "Unknown"
    }

    /// 资源类型
    var type: RenditionType {
        if rendition is TKBitmapRendition {
            return .image
        } else if rendition is TKColorRendition || rendition is TKThemeColorRendition {
            return .color
        } else if rendition is TKGradientRendition {
            return .gradient
        } else if rendition is TKEffectRendition {
            return .effect
        } else if rendition is TKPDFRendition {
            return .pdf
        } else if rendition is TKSVGRendition {
            return .svg
        } else if rendition is TKRawDataRendition {
            return .rawData
        }
        return .unknown
    }

    /// 预览图片
    var previewImage: NSImage? {
        if _cachedPreview == nil {
            rendition.computePreviewImageIfNecessary()
            _cachedPreview = rendition.previewImage
        }
        return _cachedPreview
    }

    /// 缩放比例
    var scale: CGFloat {
        rendition.scaleFactor
    }

    /// 缩放显示文本 (@1x, @2x, @3x)
    var scaleText: String {
        let s = Int(scale)
        return s > 1 ? "@\(s)x" : ""
    }

    /// 是否有分辨率标识（用于筛选）
    var hasScaleIdentifier: Bool {
        // PDF、SVG 等矢量格式通常没有分辨率标识
        if type == .pdf || type == .svg || type == .color || type == .gradient || type == .effect {
            return false
        }
        // 位图类型看 scale 是否大于 1
        return scale > 1
    }

    /// 是否为位图类型
    var isBitmap: Bool {
        rendition is TKBitmapRendition
    }

    /// 获取位图渲染对象
    var bitmapRendition: TKBitmapRendition? {
        rendition as? TKBitmapRendition
    }

    /// 获取颜色渲染对象
    var colorRendition: TKColorRendition? {
        rendition as? TKColorRendition
    }

    /// 图片尺寸（仅位图有效）
    var imageSize: CGSize? {
        guard let bitmap = bitmapRendition, let image = bitmap.image else { return nil }
        return CGSize(width: image.pixelsWide, height: image.pixelsHigh)
    }

    /// 尺寸显示文本
    var sizeText: String {
        guard let size = imageSize else { return "" }
        return "\(Int(size.width)) × \(Int(size.height))"
    }

    /// Idiom 类型
    var idiom: String {
        switch rendition.idiom {
        case .universal: return "Universal"
        case .phone: return "iPhone"
        case .pad: return "iPad"
        case .TV: return "Apple TV"
        case .car: return "CarPlay"
        case .watch: return "Watch"
        case .marketing: return "Marketing"
        @unknown default: return "Unknown"
        }
    }

    // MARK: - Hashable

    static func == (lhs: RenditionItem, rhs: RenditionItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - 操作

    /// 刷新预览图缓存
    func refreshPreview() {
        _cachedPreview = nil
        rendition.computePreviewImageIfNecessary()
        _cachedPreview = rendition.previewImage
    }
}
