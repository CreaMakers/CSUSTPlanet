//
//  UserAgreementView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/19.
//

import MarkdownUI
import SwiftUI

struct UserAgreementView: View {
    @Bindable var globalManager = GlobalManager.shared

    var isButtonPresented: Bool

    var body: some View {
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

            if isButtonPresented {
                Section {
                    Button(action: { globalManager.isUserAgreementAccepted = true }) {
                        Text("同意并继续使用")
                    }
                    .tint(.accentColor)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("用户协议")
    }
}
