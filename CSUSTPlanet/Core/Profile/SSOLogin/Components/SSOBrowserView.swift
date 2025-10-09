//
//  SSOBrowserView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/9.
//

import SwiftUI
import WebKit

struct SSOBrowserView: UIViewRepresentable {
    enum LoginMode {
        case username
        case dynamic
    }

    @State var username: String = ""
    @State var password: String = ""
    @State var loginMode: LoginMode = .username
    var onLoginSuccess: (String, String, LoginMode, [HTTPCookie]) -> Void

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: SSOBrowserView

        init(_ parent: SSOBrowserView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let js = """
                (function() {
                    function watchInput(id, fieldName) {
                        const input = document.getElementById(id);
                        if (!input) return;
                        const sendValue = () => {
                            window.webkit.messageHandlers.fieldChanged.postMessage({
                                field: fieldName,
                                value: input.value
                            });
                        };
                        input.addEventListener('input', sendValue);
                        const observer = new MutationObserver(sendValue);
                        observer.observe(input, { attributes: true, attributeFilter: ['value'] });
                    }
                    watchInput('username', 'username');
                    watchInput('password', 'password');
                })();
                """
            webView.evaluateJavaScript(js)
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            if url.absoluteString.contains("login?type=userNameLogin") {
                parent.loginMode = .username
            } else if url.absoluteString.contains("login?type=dynamicLogin") {
                parent.loginMode = .dynamic
            }

            if url == URL(string: "https://ehall.csust.edu.cn/index.html") || url == URL(string: "https://ehall.csust.edu.cn/default/index.html") {
                webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
                    guard let self = self else { return }
                    parent.onLoginSuccess(parent.username, parent.password, parent.loginMode, cookies)
                }
            }
            decisionHandler(.allow)
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "fieldChanged",
                let body = message.body as? [String: String],
                let field = body["field"],
                let value = body["value"]
            {

                DispatchQueue.main.async {
                    switch field {
                    case "username":
                        self.parent.username = value
                    case "password":
                        self.parent.password = value
                    default:
                        break
                    }
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "fieldChanged")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: URL(string: "https://authserver.csust.edu.cn/authserver/login?service=https%3A%2F%2Fehall.csust.edu.cn%2Flogin")!))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
