//
//  ScaleFilter.swift
//  CarViewer
//
//  分辨率筛选枚举
//

import Foundation

/// 分辨率筛选选项
enum ScaleFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case scale1x = "1x"
    case scale2x = "2x"
    case scale3x = "3x"
    case noScale = "none"  // 无标识（PDF/SVG等）

    var id: String { rawValue }

    /// 对应的缩放值（nil 表示全部）
    var scaleValue: CGFloat? {
        switch self {
        case .all: return nil
        case .scale1x: return 1.0
        case .scale2x: return 2.0
        case .scale3x: return 3.0
        case .noScale: return 0  // 特殊标记
        }
    }

    /// 本地化显示名称
    var localizedName: String {
        let isChinese = Locale.current.language.languageCode?.identifier == "zh"
        switch self {
        case .all: return isChinese ? "全部分辨率" : "All Scales"
        case .scale1x: return "@1x"
        case .scale2x: return "@2x"
        case .scale3x: return "@3x"
        case .noScale: return isChinese ? "无标识" : "No Scale"
        }
    }

    /// 系统图标
    var systemImage: String {
        switch self {
        case .all: return "square.grid.3x3"
        case .scale1x: return "1.circle"
        case .scale2x: return "2.circle"
        case .scale3x: return "3.circle"
        case .noScale: return "questionmark.circle"
        }
    }

    /// 提示说明
    var hint: String {
        let isChinese = Locale.current.language.languageCode?.identifier == "zh"
        switch self {
        case .all:
            return isChinese ? "显示所有分辨率的资源" : "Show assets of all resolutions"
        case .scale1x:
            return isChinese ? "基础分辨率，适用于老旧非 Retina 设备（已基本淘汰）" : "Base resolution for legacy non-Retina devices (mostly obsolete)"
        case .scale2x:
            return isChinese ? "2倍分辨率，适用于大多数 iPhone/iPad/Mac Retina 设备" : "2x resolution for most iPhone/iPad/Mac Retina devices"
        case .scale3x:
            return isChinese ? "3倍分辨率，适用于 iPhone Plus/Pro Max 等超高清设备" : "3x resolution for iPhone Plus/Pro Max and other high-DPI devices"
        case .noScale:
            return isChinese ? "无分辨率标识的资源（如 PDF、SVG 等矢量格式）" : "Assets without scale identifier (e.g., PDF, SVG vector formats)"
        }
    }
}

/// 导出分辨率选项
enum ExportScaleOption: String, CaseIterable, Identifiable {
    case all = "all"
    case scale1x = "1x"
    case scale2x = "2x"
    case scale3x = "3x"
    case scale2xAnd3x = "2x+3x"
    case highest = "highest"

    var id: String { rawValue }

    /// 本地化显示名称
    var localizedName: String {
        let isChinese = Locale.current.language.languageCode?.identifier == "zh"
        switch self {
        case .all: return isChinese ? "全部分辨率" : "All Scales"
        case .scale1x: return isChinese ? "仅 @1x" : "Only @1x"
        case .scale2x: return isChinese ? "仅 @2x" : "Only @2x"
        case .scale3x: return isChinese ? "仅 @3x" : "Only @3x"
        case .scale2xAnd3x: return isChinese ? "@2x 和 @3x" : "@2x and @3x"
        case .highest: return isChinese ? "仅最高分辨率" : "Highest Only"
        }
    }

    /// 提示说明
    var hint: String {
        let isChinese = Locale.current.language.languageCode?.identifier == "zh"
        switch self {
        case .all:
            return isChinese
                ? "导出所有分辨率版本，适合需要完整资源的场景"
                : "Export all resolution variants, for complete asset coverage"
        case .scale1x:
            return isChinese
                ? "导出 @1x 基础分辨率，文件最小但画质最低"
                : "Export @1x base resolution, smallest files but lowest quality"
        case .scale2x:
            return isChinese
                ? "导出 @2x 分辨率，适用于大多数现代设备"
                : "Export @2x resolution, suitable for most modern devices"
        case .scale3x:
            return isChinese
                ? "导出 @3x 最高分辨率，画质最佳但文件较大"
                : "Export @3x highest resolution, best quality but larger files"
        case .scale2xAnd3x:
            return isChinese
                ? "导出 @2x 和 @3x，推荐用于新 iOS/macOS 项目"
                : "Export @2x and @3x, recommended for new iOS/macOS projects"
        case .highest:
            return isChinese
                ? "每个资源只导出最高分辨率版本，适合 Web 或设计稿使用"
                : "Export only the highest resolution for each asset, ideal for web or design"
        }
    }

    /// 系统图标
    var systemImage: String {
        switch self {
        case .all: return "square.grid.3x3"
        case .scale1x: return "1.circle"
        case .scale2x: return "2.circle"
        case .scale3x: return "3.circle"
        case .scale2xAnd3x: return "rectangle.on.rectangle"
        case .highest: return "arrow.up.circle"
        }
    }

    /// 判断资源是否匹配此导出选项
    func matches(scale: CGFloat) -> Bool {
        switch self {
        case .all: return true
        case .scale1x: return scale == 1.0
        case .scale2x: return scale == 2.0
        case .scale3x: return scale == 3.0
        case .scale2xAnd3x: return scale == 2.0 || scale == 3.0
        case .highest: return true // 需要特殊处理
        }
    }
}
