//
//  AssignmentsCoursePage.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/20.
//

import CSUSTKit
import SwiftUI

struct AssignmentsCoursePage: View {
    let courseID: String
    @State private var webViewController = WebViewController()

    var originalURL: URL? { URL(string: "http://pt.csust.edu.cn/meol/jpk/course/layout/newpage/index.jsp?courseId=\(courseID)") }
    var vpnURL: URL? {
        if let originalURL {
            try? WebVPNHelper.encryptURL(originalURL)
        } else {
            nil
        }
    }

    var url: URL? {
        if MMKVHelper.GlobalManager.isWebVPNModeEnabled {
            vpnURL
        } else {
            originalURL
        }
    }

    var body: some View {
        Group {
            if let url {
                WebView(
                    url: url,
                    cookies: CookieHelper.shared.session.session.configuration.httpCookieStorage?.cookies,
                    controller: webViewController
                )
            } else {
                ContentUnavailableView("无法打开课程页面", systemImage: "exclamationmark.triangle", description: Text("课程链接无效"))
            }
        }
        .navigationTitle("课程页面")
        .inlineToolbarTitle()
        .toolbar {
            WebViewControlsToolbar(controller: webViewController)
        }
    }
}
