//
//  ExportOptionsSheet.swift
//  CarViewer
//
//  导出选项面板 - 选择导出分辨率
//

import SwiftUI

struct ExportOptionsSheet: View {
    @Environment(AssetStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var isChinese: Bool {
        Locale.current.language.languageCode?.identifier == "zh"
    }

    var body: some View {
        @Bindable var store = store

        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text(isChinese ? "导出选项" : "Export Options")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // 内容区
            VStack(alignment: .leading, spacing: 20) {
                // 待导出信息
                HStack {
                    Image(systemName: "photo.stack")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isChinese ? "待导出资源" : "Assets to Export")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(store.pendingExportItems.count)")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // 分辨率选择
                VStack(alignment: .leading, spacing: 12) {
                    Text(isChinese ? "选择导出分辨率" : "Select Export Resolution")
                        .font(.headline)

                    ForEach(ExportScaleOption.allCases) { option in
                        ExportOptionRow(
                            option: option,
                            isSelected: store.exportScaleOption == option,
                            action: { store.exportScaleOption = option }
                        )
                    }
                }

                Spacer()
            }
            .padding()

            Divider()

            // 底部按钮
            HStack {
                Button(isChinese ? "取消" : "Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    store.confirmExport()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text(isChinese ? "开始导出" : "Export")
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 480, height: 520)
    }
}

// MARK: - 导出选项行
struct ExportOptionRow: View {
    let option: ExportScaleOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // 选中指示器
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .secondary)

                // 图标
                Image(systemName: option.systemImage)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .primary)
                    .frame(width: 28)

                // 文本
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.localizedName)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(.primary)

                    Text(option.hint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ExportOptionsSheet()
        .environment(AssetStore())
}
