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

            Section {
                NavigationLink(destination: TesterListView()) {
                    Label("测试人员名单", systemImage: "person.3.fill")
                }
            }

            Section("应用信息") {
                HStack {
                    Text("版本号")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "未知版本")
                }
                HStack {
                    Text("构建号")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "未知构建")
                }
                HStack {
                    Text("运行环境")
                    Spacer()
                    switch AppEnvironmentHelper.environment {
                    case .debug:
                        Text("Debug")
                    case .appStore:
                        Text("App Store")
                    case .testFlight:
                        Text("TestFlight")
                    }
                }
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
                        MMKVManager.shared.clearAll()
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
