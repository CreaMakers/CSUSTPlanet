//
//  AboutView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import MarkdownUI
import SwiftUI

#if DEBUG
    import FLEX
#endif

struct AboutView: View {
    var body: some View {
        Form {
            if let aboutMarkdown = AssetHelper.loadMarkdownFile(named: "About") {
                Markdown(aboutMarkdown)
            } else {
                Text("无法加载关于信息")
            }

            Section("应用信息") {
                InfoRow(label: "版本号", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "未知版本")
                InfoRow(label: "构建号", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "未知构建")
                InfoRow(label: "运行环境", value: AppEnvironmentHelper.environment.rawValue)
            }

            #if DEBUG
                Section("Debug") {
                    Button(action: {
                        try? SharedModelHelper.clearAllData()
                    }) {
                        Label("清除所有SwiftData数据", systemImage: "trash")
                            .foregroundColor(.red)
                    }

                    Button(action: {
                        MMKVHelper.shared.clearAll()
                    }) {
                        Label("清除所有MMKV数据", systemImage: "trash")
                            .foregroundColor(.red)
                    }

                    Button(action: {
                        KeychainHelper.shared.deleteAll()
                    }) {
                        Label("清除所有Keychain数据", systemImage: "trash")
                            .foregroundColor(.red)
                    }

                    Button(action: {
                        FLEXManager.shared.showExplorer()
                    }) {
                        Label("Flipboard Explorer", systemImage: "ladybug.fill")
                            .foregroundColor(.blue)
                    }
                }
            #endif
        }
        .background(Color(.systemBackground))
        .navigationTitle("关于")
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
