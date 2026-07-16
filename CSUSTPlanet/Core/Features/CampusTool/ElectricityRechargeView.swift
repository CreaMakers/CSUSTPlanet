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
            WebViewControlsToolbar(controller: webViewController)
        }
    }
}

#Preview {
    ElectricityRechargeView()
}
