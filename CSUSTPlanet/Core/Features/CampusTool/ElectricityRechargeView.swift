//
//  ElectricityRechargeView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/13.
//

import CSUSTKit
import SwiftUI

struct ElectricityRechargeView: View {
    @State private var webViewController = WebViewController()

    var originalURL: URL { URL(string: "https://hxyxh5.csust.edu.cn/plat/shouyeUser")! }
    var vpnURL: URL { try! WebVPNHelper.encryptURL(originalURL) }

    var url: URL {
        if MMKVHelper.GlobalManager.isWebVPNModeEnabled {
            vpnURL
        } else {
            originalURL
        }
    }

    var body: some View {
        WebView(
            url: url,
            cookies: CookieHelper.shared.session.sessionConfiguration.httpCookieStorage?.cookies,
            controller: webViewController
        )
        .inlineToolbarTitle()
        .navigationTitle("电费充值")
        .toolbar {
            ToolbarItemGroup(placement: .secondaryAction) {
                Button(action: { webViewController.goBack() }) {
                    Label("上一页", systemImage: "chevron.left")
                }
                .disabled(!webViewController.canGoBack)

                Button(action: { webViewController.goForward() }) {
                    Label("下一页", systemImage: "chevron.right")
                }
                .disabled(!webViewController.canGoForward)
            }

            ToolbarItem(placement: .primaryAction) {
                Button(action: { webViewController.reload() }) {
                    if webViewController.isLoading {
                        ProgressView().smallControlSizeOnMac()
                    } else {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

#Preview {
    ElectricityRechargeView()
}
