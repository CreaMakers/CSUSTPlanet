//
//  UserAgreementView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/19.
//

import MarkdownUI
import SwiftUI

struct UserAgreementView: View {
    @EnvironmentObject var globalManager: GlobalManager

    var body: some View {
        NavigationStack {
            Form {
                if let userAgreementMarkdown = AssetUtil.loadMarkdownFile(named: "UserAgreement") {
                    Markdown(userAgreementMarkdown)
                        .markdownTextStyle(\.strong) {
                            ForegroundColor(.primary)
                            BackgroundColor(.yellow.opacity(0.3))
                            FontWeight(.bold)
                        }
                } else {
                    Text("无法加载用户协议")
                }
                Section {
                    Button(action: {
                        globalManager.isUserAgreementAccepted = true
                    }) {
                        Text("同意并继续使用")
                    }
                    .tint(.blue)
                    Button(action: {
                        globalManager.isUserAgreementAccepted = false
                        exit(0)
                    }) {
                        Text("不同意并退出")
                    }
                    .tint(.red)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("用户协议")
        }
        .trackView("UserAgreement")
    }
}

#Preview {
    NavigationStack {
        UserAgreementView()
            .environmentObject(GlobalManager.shared)
    }
}
