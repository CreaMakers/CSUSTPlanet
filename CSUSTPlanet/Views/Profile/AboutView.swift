//
//  AboutView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import MarkdownUI
import SwiftUI

struct AboutView: View {
    var body: some View {
        Form {
            if let aboutMarkdown = AssetUtils.loadMarkdownFile(named: "About") {
                Markdown(aboutMarkdown)
            } else {
                Text("无法加载关于信息")
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
                    switch AppEnvironmentHelper.currentEnvironment() {
                    case .debug:
                        Text("Debug")
                    case .appStore:
                        Text("App Store")
                    case .testFlight:
                        Text("TestFlight")
                    }
                }
            }
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
