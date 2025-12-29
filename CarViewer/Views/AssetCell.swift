//
//  AssetCell.swift
//  CarViewer
//
//  资源单元格视图 - 显示单个资源的预览
//

import SwiftUI

struct AssetCell: View {
    @Environment(AssetStore.self) private var store
    let item: RenditionItem

    /// 是否选中
    private var isSelected: Bool {
        store.selectedItems.contains(item.id)
    }

    /// 单元格尺寸
    private var cellSize: CGFloat {
        100 * store.gridScale
    }

    var body: some View {
        VStack(spacing: 8) {
            // 预览区域
            previewView
                .frame(width: cellSize, height: cellSize)
                .background(checkeredBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

            // 名称和信息
            VStack(spacing: 2) {
                Text(item.name)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isSelected ? .primary : .secondary)

                HStack(spacing: 4) {
                    // 类型图标
                    Image(systemName: item.type.systemImage)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    // 尺寸或缩放
                    if !item.sizeText.isEmpty {
                        Text(item.sizeText)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    if !item.scaleText.isEmpty {
                        Text(item.scaleText)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .frame(width: cellSize + 20)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
    }

    // MARK: - 预览视图

    @ViewBuilder
    private var previewView: some View {
        switch item.type {
        case .image, .pdf, .svg:
            imagePreview

        case .color:
            colorPreview

        case .gradient:
            gradientPreview

        case .effect:
            effectPreview

        default:
            unknownPreview
        }
    }

    /// 图片预览
    @ViewBuilder
    private var imagePreview: some View {
        if let nsImage = item.previewImage {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(8)
        } else {
            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
        }
    }

    /// 颜色预览
    @ViewBuilder
    private var colorPreview: some View {
        if let colorRendition = item.colorRendition,
           let nsColor = colorRendition.color {
            Color(nsColor: nsColor)
                .overlay(
                    VStack {
                        Spacer()
                        Text(hexString(from: nsColor))
                            .font(.caption2)
                            .fontDesign(.monospaced)
                            .padding(4)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .padding(4)
                    }
                )
        } else if let nsImage = item.previewImage {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Rectangle()
                .fill(.tertiary)
        }
    }

    /// 渐变预览
    @ViewBuilder
    private var gradientPreview: some View {
        if let nsImage = item.previewImage {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    /// 效果预览
    @ViewBuilder
    private var effectPreview: some View {
        if let nsImage = item.previewImage {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(8)
        } else {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
        }
    }

    /// 未知类型预览
    private var unknownPreview: some View {
        Image(systemName: "questionmark.square.dashed")
            .font(.largeTitle)
            .foregroundStyle(.tertiary)
    }

    /// 棋盘格背景（用于显示透明区域）
    private var checkeredBackground: some View {
        Canvas { context, size in
            let tileSize: CGFloat = 8
            let rows = Int(ceil(size.height / tileSize))
            let cols = Int(ceil(size.width / tileSize))

            for row in 0..<rows {
                for col in 0..<cols {
                    let isLight = (row + col) % 2 == 0
                    let rect = CGRect(
                        x: CGFloat(col) * tileSize,
                        y: CGFloat(row) * tileSize,
                        width: tileSize,
                        height: tileSize
                    )
                    context.fill(
                        Path(rect),
                        with: .color(isLight ? .white : Color(white: 0.9))
                    )
                }
            }
        }
    }

    // MARK: - 辅助方法

    private func hexString(from color: NSColor) -> String {
        guard let rgb = color.usingColorSpace(.sRGB) else { return "" }
        let r = Int(rgb.redComponent * 255)
        let g = Int(rgb.greenComponent * 255)
        let b = Int(rgb.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

#Preview {
    HStack {
        // 模拟不同类型的单元格预览
        VStack {
            Text("Image")
            RoundedRectangle(cornerRadius: 8)
                .fill(.blue.opacity(0.3))
                .frame(width: 100, height: 100)
        }

        VStack {
            Text("Color")
            RoundedRectangle(cornerRadius: 8)
                .fill(.red)
                .frame(width: 100, height: 100)
        }
    }
    .padding()
}
