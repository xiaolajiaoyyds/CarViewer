//
//  AssetGridView.swift
//  CarViewer
//
//  资源网格视图 - Photos 风格的网格布局
//

import SwiftUI

struct AssetGridView: View {
    @Environment(AssetStore.self) private var store

    /// 根据缩放比例计算的网格列
    private var columns: [GridItem] {
        let baseSize: CGFloat = 120 * store.gridScale
        return [GridItem(.adaptive(minimum: baseSize, maximum: baseSize * 1.5), spacing: 16)]
    }

    var body: some View {
        @Bindable var store = store

        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(store.filteredRenditions) { item in
                    AssetCell(item: item)
                        .onTapGesture {
                            handleTap(item: item)
                        }
                        .contextMenu {
                            contextMenu(for: item)
                        }
                }
            }
            .padding(16)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - 交互处理

    private func handleTap(item: RenditionItem) {
        if NSEvent.modifierFlags.contains(.command) {
            // Command + 点击：切换选择
            if store.selectedItems.contains(item.id) {
                store.selectedItems.remove(item.id)
            } else {
                store.selectedItems.insert(item.id)
            }
        } else if NSEvent.modifierFlags.contains(.shift) {
            // Shift + 点击：范围选择
            store.selectedItems.insert(item.id)
        } else {
            // 普通点击：单选
            store.selectedItems = [item.id]
            store.showDetail = true
        }
    }

    // MARK: - 右键菜单

    @ViewBuilder
    private func contextMenu(for item: RenditionItem) -> some View {
        Button(String(localized: "menu.export")) {
            exportSingle(item)
        }

        if item.isBitmap {
            Button(String(localized: "menu.replace")) {
                replaceImage(item)
            }
        }

        Divider()

        Button(String(localized: "menu.copyName")) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(item.name, forType: .string)
        }

        if let size = item.imageSize {
            Button(String(localized: "menu.copySize")) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString("\(Int(size.width)) × \(Int(size.height))", forType: .string)
            }
        }
    }

    // MARK: - 操作

    private func exportSingle(_ item: RenditionItem) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = item.name + ".png"
        panel.allowedContentTypes = [.png]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        Task {
            try? await ExportService.shared.exportItem(item, to: url.deletingLastPathComponent())
        }
    }

    private func replaceImage(_ item: RenditionItem) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff]
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK,
              let url = panel.url,
              let image = NSImage(contentsOf: url) else { return }

        store.replaceImage(for: item, with: image)
    }
}

#Preview {
    AssetGridView()
        .environment(AssetStore())
        .frame(width: 600, height: 400)
}
