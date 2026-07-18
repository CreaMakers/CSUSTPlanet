//
//  EvalBrowserView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/7/17.
//

import CSUSTKit
import SwiftUI
import WebKit

struct EvalBrowserView: PlatformViewRepresentable {
    private static let factory = URLFactory(mode: AuthManager.shared.mode)
    private static let autofillStateMessageName = "evaluationAutofillState"

    let controller: WebViewController
    let autofillController: EvalAutofillController

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        weak var controller: WebViewController?
        weak var autofillController: EvalAutofillController?

        init(controller: WebViewController, autofillController: EvalAutofillController) {
            self.controller = controller
            self.autofillController = autofillController
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            controller?.syncState()
            autofillController?.updateAvailability(false)
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

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == EvalBrowserView.autofillStateMessageName,
                message.frameInfo.isMainFrame,
                let body = message.body as? [String: Any],
                let isAvailable = body["isAvailable"] as? Bool
            else {
                return
            }

            autofillController?.updateAvailability(isAvailable)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller, autofillController: autofillController)
    }

    private func makeWebView(coordinator: Coordinator) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let dataStore = WKWebsiteDataStore.nonPersistent()
        configuration.websiteDataStore = dataStore
        configuration.userContentController.add(coordinator, name: Self.autofillStateMessageName)

        let viewportSource = """
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=1280, initial-scale=0.3, maximum-scale=5.0, minimum-scale=0.1';
            document.head.appendChild(meta);
            """

        configuration.userContentController.addUserScript(
            WKUserScript(source: viewportSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        )

        if let scriptURL = Bundle.main.url(forResource: "EvalAutofill", withExtension: "js"),
            let scriptSource = try? String(contentsOf: scriptURL, encoding: .utf8)
        {
            configuration.userContentController.addUserScript(
                WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            )
        }

        let webView = WKWebView(frame: .zero, configuration: configuration)

        webView.navigationDelegate = coordinator

        controller.webView = webView
        controller.syncState()
        autofillController.webView = webView
        autofillController.updateAvailability(false)

        let cookies = CookieHelper.shared.session.sessionConfiguration.httpCookieStorage?.cookies ?? []
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
