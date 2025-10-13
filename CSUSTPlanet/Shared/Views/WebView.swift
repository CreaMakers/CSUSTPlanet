//
//  WebView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    let cookies: [HTTPCookie]?

    init(url: URL, cookies: [HTTPCookie]? = nil) {
        self.url = url
        self.cookies = cookies
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let dataStore = WKWebsiteDataStore.nonPersistent()
        if let cookies = cookies {
            let cookieStore = dataStore.httpCookieStore
            for cookie in cookies {
                cookieStore.setCookie(cookie)
            }
        }

        configuration.websiteDataStore = dataStore
        let webView = WKWebView(frame: .zero, configuration: configuration)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
