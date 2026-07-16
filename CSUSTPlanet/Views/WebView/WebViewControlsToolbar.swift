//
//  WebViewControlsToolbar.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/7/17.
//

import SwiftUI

struct WebViewControlsToolbar: ToolbarContent {
    @Bindable var controller: WebViewController

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .secondaryAction) {
            Button(action: { controller.goBack() }) {
                Label("上一页", systemImage: "chevron.left")
            }
            .disabled(!controller.canGoBack)

            Button(action: { controller.goForward() }) {
                Label("下一页", systemImage: "chevron.right")
            }
            .disabled(!controller.canGoForward)
        }

        ToolbarItem(placement: .primaryAction) {
            Button(action: { controller.reload() }) {
                if controller.isLoading {
                    ProgressView().smallControlSizeOnMac()
                } else {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
            }
        }
    }
}
