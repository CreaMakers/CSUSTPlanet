//
//  NCREView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/5/29.
//

import SwiftUI

struct NCREView: View {
    @State private var webViewController = WebViewController()

    var body: some View {
        WebView(
            url: URL(string: "https://cjcx.neea.edu.cn/html1/folder/22014/5490-1.htm")!,
            controller: webViewController
        )
        .navigationTitle("计算机等级查询")
        .inlineToolbarTitle()
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
