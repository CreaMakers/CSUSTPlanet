//
//  MandarinView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import SwiftUI

struct MandarinView: View {
    @State private var webViewController = WebViewController()

    var body: some View {
        WebView(
            url: URL(string: "https://zwfw.moe.gov.cn/mandarin/")!,
            controller: webViewController
        )
        .navigationTitle("普通话查询")
        .inlineToolbarTitle()
        .toolbar {
            WebViewControlsToolbar(controller: webViewController)
        }
    }
}

#Preview {
    MandarinView()
}
