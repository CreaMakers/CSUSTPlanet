//
//  UserAgreementView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/19.
//

import MarkdownUI
import SwiftUI

struct UserAgreementView: View {
    @EnvironmentObject var globalVars: GlobalVars

    var body: some View {
        NavigationStack {
            Form {
                if let userAgreementMarkdown = AssetUtils.loadMarkdownFile(named: "UserAgreement") {
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
                        globalVars.isUserAgreementAccepted = true
                    }) {
                        Text("同意并继续使用")
                    }
                    .tint(.blue)
                    Button(action: {
                        globalVars.isUserAgreementAccepted = false
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
    }
}

#Preview {
    NavigationStack {
        UserAgreementView()
            .environmentObject(GlobalVars.shared)
    }
}
