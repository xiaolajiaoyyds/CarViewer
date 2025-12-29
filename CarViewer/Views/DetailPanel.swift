//
//  DetailPanel.swift
//  CarViewer
//
//  详情面板 - Inspector 风格的资源详情视图
//

import SwiftUI

struct DetailPanel: View {
    @Environment(AssetStore.self) private var store
    let item: RenditionItem

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 预览图
                previewSection

                Divider()

                // 基本信息
                infoSection

                Divider()

                // 操作按钮
                actionSection
            }
            .padding()
        }
        .inspectorColumnWidth(min: 250, ideal: 300, max: 400)
    }

    // MARK: - 预览区域

    private var previewSection: some View {
        VStack(spacing: 12) {
            Text(item.name)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            if let nsImage = item.previewImage {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 200, maxHeight: 200)
                    .background(checkeredBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 150, height: 150)
                    .overlay(
                        Image(systemName: item.type.systemImage)
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)
                    )
            }
        }
    }

    // MARK: - 信息区域

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 类型
            InfoRow(
                label: String(localized: "detail.type"),
                value: item.type.localizedName,
                icon: item.type.systemImage
            )

            // 元素名称
            InfoRow(
                label: String(localized: "detail.element"),
                value: item.elementName,
                icon: "folder"
            )

            // 尺寸（如果适用）
            if let size = item.imageSize {
                InfoRow(
                    label: String(localized: "detail.size"),
                    value: "\(Int(size.width)) × \(Int(size.height)) px",
                    icon: "aspectratio"
                )
            }

            // 缩放
            if item.scale > 1 {
                InfoRow(
                    label: String(localized: "detail.scale"),
                    value: "@\(Int(item.scale))x",
                    icon: "square.2.layers.3d"
                )
            }

            // Idiom
            InfoRow(
                label: String(localized: "detail.idiom"),
                value: item.idiom,
                icon: "desktopcomputer"
            )

            // 颜色信息（如果是颜色类型）
            if let colorRendition = item.colorRendition,
               let color = colorRendition.color {
                colorInfoSection(color)
            }
        }
    }

    // MARK: - 颜色信息

    @ViewBuilder
    private func colorInfoSection(_ color: NSColor) -> some View {
        if let rgb = color.usingColorSpace(.sRGB) {
            let r = Int(rgb.redComponent * 255)
            let g = Int(rgb.greenComponent * 255)
            let b = Int(rgb.blueComponent * 255)
            let a = rgb.alphaComponent

            Group {
                InfoRow(
                    label: "HEX",
                    value: String(format: "#%02X%02X%02X", r, g, b),
                    icon: "number"
                )

                InfoRow(
                    label: "RGB",
                    value: "\(r), \(g), \(b)",
                    icon: "paintpalette"
                )

                if a < 1.0 {
                    InfoRow(
                        label: String(localized: "detail.opacity"),
                        value: String(format: "%.0f%%", a * 100),
                        icon: "circle.lefthalf.filled"
                    )
                }
            }
        }
    }

    // MARK: - 操作区域

    private var actionSection: some View {
        VStack(spacing: 12) {
            // 导出按钮
            Button {
                exportItem()
            } label: {
                Label(String(localized: "detail.export"), systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            // 替换按钮（仅位图）
            if item.isBitmap {
                Button {
                    replaceImage()
                } label: {
                    Label(String(localized: "detail.replace"), systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            // 复制名称
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(item.name, forType: .string)
            } label: {
                Label(String(localized: "detail.copyName"), systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - 操作方法

    private func exportItem() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = item.name + ".png"
        panel.allowedContentTypes = [.png]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        Task {
            try? await ExportService.shared.exportItem(item, to: url.deletingLastPathComponent())
        }
    }

    private func replaceImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff]
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK,
              let url = panel.url,
              let image = NSImage(contentsOf: url) else { return }

        store.replaceImage(for: item, with: image)
    }

    // MARK: - 辅助视图

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
}

// MARK: - 信息行组件

struct InfoRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.callout)
                    .textSelection(.enabled)
            }

            Spacer()
        }
    }
}

#Preview {
    DetailPanel(item: RenditionItem(
        rendition: TKBitmapRendition(),
        elementName: "AppIcon"
    ))
    .environment(AssetStore())
    .frame(width: 300, height: 600)
}
