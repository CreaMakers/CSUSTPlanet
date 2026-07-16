//
//  WebVPNConverterView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/6/17.
//

import CSUSTKit
import SwiftUI
import WebKit

struct EvalView: View {
    @State private var webViewController = WebViewController()

    var body: some View {
        HStack {
            EvalBrowserView(controller: webViewController)
        }
        .inlineToolbarTitle()
        .navigationTitle("评教系统")
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

struct EvalBrowserView: PlatformViewRepresentable {
    static let factory = URLFactory(mode: AuthManager.shared.mode)
    let controller: WebViewController

    class Coordinator: NSObject, WKNavigationDelegate {
        weak var controller: WebViewController?

        init(controller: WebViewController) {
            self.controller = controller
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            controller?.syncState()
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            controller?.syncState()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            controller?.syncState()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
            controller?.syncState()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
            controller?.syncState()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller)
    }

    private func makeWebView(coordinator: Coordinator) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let dataStore = WKWebsiteDataStore.nonPersistent()
        configuration.websiteDataStore = dataStore

        let webView = WKWebView(frame: .zero, configuration: configuration)

        let source = """
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=1280, initial-scale=0.3, maximum-scale=5.0, minimum-scale=0.1';
            document.head.appendChild(meta);
            """

        let script = WKUserScript(
            source: source,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )

        configuration.userContentController.addUserScript(script)

        webView.navigationDelegate = coordinator

        controller.webView = webView
        controller.syncState()

        if let cookies = CookieHelper.shared.session.sessionConfiguration.httpCookieStorage?.cookies {
            let cookieStore = dataStore.httpCookieStore
            let group = DispatchGroup()

            for cookie in cookies {
                group.enter()
                cookieStore.setCookie(cookie) {
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                webView.load(URLRequest(url: URL(string: Self.factory.make(.eval, "/api/manage/cas/toUrl?type=pc"))!))
            }
        }

        return webView
    }

    #if os(iOS)
    func makeUIView(context: Context) -> WKWebView {
        makeWebView(coordinator: context.coordinator)
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
    #endif

    #if os(macOS)
    func makeNSView(context: Context) -> WKWebView {
        makeWebView(coordinator: context.coordinator)
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
    #endif
}
