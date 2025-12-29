//
//  SidebarView.swift
//  CarViewer
//
//  侧边栏视图 - 按类型分组快速筛选
//

import SwiftUI

struct SidebarView: View {
    @Environment(AssetStore.self) private var store

    private var isChinese: Bool {
        Locale.current.language.languageCode?.identifier == "zh"
    }

    var body: some View {
        @Bindable var store = store

        VStack(spacing: 0) {
            // 分类列表
            List(selection: $store.filterType) {
                Section(isChinese ? "分类" : "Categories") {
                    ForEach(RenditionType.allCases) { type in
                        NavigationLink(value: type) {
                            Label {
                                HStack {
                                    Text(type.localizedName)
                                    Spacer()
                                    Text("\(countForType(type))")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                            } icon: {
                                Image(systemName: type.systemImage)
                            }
                        }
                        .contextMenu {
                            if type != .all && countForType(type) > 0 {
                                Button {
                                    store.exportType(type)
                                } label: {
                                    Label(isChinese ? "导出全部\(type.localizedName)" : "Export All \(type.localizedName)", systemImage: "square.and.arrow.up")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)

            Divider()

            // 赞赏区域
            VStack(spacing: 8) {
                // 赞赏码图片
                if let image = NSImage(contentsOfFile: Bundle.main.resourcePath! + "/zanshangma.png") {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Text(isChinese
                     ? "觉得不错对你有用\n请作者喝一杯咖啡吧"
                     : "If you find it useful\nBuy me a coffee")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text(isChinese ? "微信扫码" : "WeChat")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 12)

            Divider()

            // 底部操作区
            VStack(spacing: 10) {
                // 导出全部按钮
                Button {
                    store.exportAll()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text(isChinese ? "导出全部资源" : "Export All Assets")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.allRenditions.isEmpty)

                // 项目信息 - 单行紧凑布局
                HStack(spacing: 12) {
                    Text("v1.0")
                        .font(.caption2)

                    Link(destination: URL(string: "https://github.com/xiaolajiaoyyds/CarViewer")!) {
                        Image(systemName: "link")
                    }

                    Link(destination: URL(string: "mailto:xiaolajiaoyyds@gmail.com")!) {
                        Image(systemName: "envelope")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(12)
        }
        .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
    }

    private func countForType(_ type: RenditionType) -> Int {
        if type == .all {
            return store.allRenditions.count
        }
        return store.allRenditions.filter { $0.type == type }.count
    }
}

#Preview {
    NavigationSplitView {
        SidebarView()
            .environment(AssetStore())
    } detail: {
        Text("Detail")
    }
}
