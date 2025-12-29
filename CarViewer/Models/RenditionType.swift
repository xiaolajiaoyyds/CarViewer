//
//  RenditionType.swift
//  CarViewer
//
//  资源类型枚举
//

import Foundation

/// 资源类型枚举，用于筛选和显示
enum RenditionType: String, CaseIterable, Identifiable {
    case all = "all"
    case image = "image"
    case color = "color"
    case gradient = "gradient"
    case effect = "effect"
    case pdf = "pdf"
    case svg = "svg"
    case rawData = "rawData"
    case unknown = "unknown"

    var id: String { rawValue }

    /// 本地化显示名称
    var localizedName: String {
        // 根据系统语言返回对应文本
        let isChinese = Locale.current.language.languageCode?.identifier == "zh"
        switch self {
        case .all: return isChinese ? "全部" : "All"
        case .image: return isChinese ? "图片" : "Images"
        case .color: return isChinese ? "颜色" : "Colors"
        case .gradient: return isChinese ? "渐变" : "Gradients"
        case .effect: return isChinese ? "效果" : "Effects"
        case .pdf: return "PDF"
        case .svg: return "SVG"
        case .rawData: return isChinese ? "原始数据" : "Raw Data"
        case .unknown: return isChinese ? "未知" : "Unknown"
        }
    }

    /// 系统图标名称
    var systemImage: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .image: return "photo"
        case .color: return "paintpalette"
        case .gradient: return "circle.lefthalf.filled"
        case .effect: return "sparkles"
        case .pdf: return "doc.richtext"
        case .svg: return "square.on.circle"
        case .rawData: return "doc.text"
        case .unknown: return "questionmark.square"
        }
    }
}
