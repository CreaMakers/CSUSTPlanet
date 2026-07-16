//
//  CETView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import SwiftUI

struct CETView: View {
    @State private var webViewController = WebViewController()

    var body: some View {
        WebView(
            url: URL(string: "https://cjcx.neea.edu.cn/html1/folder/21033/653-1.htm")!,
            controller: webViewController
        )
        .navigationTitle("四六级查询")
        .inlineToolbarTitle()
        .toolbar {
            WebViewControlsToolbar(controller: webViewController)
        }
    }
}

#Preview {
    CETView()
}
