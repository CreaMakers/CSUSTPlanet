//
//  SSOLoginContent.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/7/19.
//

import Foundation
import SwiftUI

private enum LoginTab: Hashable {
    case account
    case web
}

struct SSOLoginContent: View {
    @State private var selectedTab: LoginTab? = .account

    let initialUsername: String
    let initialPassword: String
    let isLoggingIn: Bool
    @Binding var errorToast: ToastState

    let onLogin: (String, String, String) async -> Void
    let onCheckNeedCaptcha: (String) async -> Bool
    let onRefreshCaptcha: () async -> Data?
    let onBrowserLoginSuccess: (String, String, SSOBrowserView.LoginMode, [HTTPCookie]) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                #if os(iOS)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        SSOAccountLoginContent(
                            username: initialUsername,
                            password: initialPassword,
                            captcha: "",
                            isNeedCaptcha: false,
                            isLoggingIn: isLoggingIn,
                            onLogin: onLogin,
                            onCheckNeedCaptcha: onCheckNeedCaptcha,
                            onRefreshCaptcha: onRefreshCaptcha
                        )
                        .containerRelativeFrame(.horizontal)
                        .id(LoginTab.account)

                        SSOBrowserView(onSuccess: onBrowserLoginSuccess)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .containerRelativeFrame(.horizontal)
                            .id(LoginTab.web)
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $selectedTab)
                #elseif os(macOS)
                NavigationSplitView {
                    List(selection: $selectedTab) {
                        Label("账号登录", systemImage: "person").tag(LoginTab.account)
                        Label("网页登录", systemImage: "globe").tag(LoginTab.web)
                    }
                } detail: {
                    switch selectedTab {
                    case .account:
                        SSOAccountLoginContent(
                            username: initialUsername,
                            password: initialPassword,
                            captcha: "",
                            isNeedCaptcha: false,
                            isLoggingIn: isLoggingIn,
                            onLogin: onLogin,
                            onCheckNeedCaptcha: onCheckNeedCaptcha,
                            onRefreshCaptcha: onRefreshCaptcha
                        )
                    case .web:
                        SSOBrowserView(onSuccess: onBrowserLoginSuccess)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    default:
                        EmptyView()
                    }
                }
                #endif
            }
            .formStyle(.grouped)
            #if os(iOS)
            .navigationTitle("统一身份认证登录")
            .inlineToolbarTitle()
            .background(Color(PlatformColor.systemGroupedBackground))
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .principal) {
                    Picker("登录方式", selection: $selectedTab) {
                        Text("账号登录").tag(LoginTab.account)
                        Text("网页登录").tag(LoginTab.web)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
                #endif

                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .errorToast($errorToast)
        }
        #if os(macOS)
        .frame(minWidth: 720, minHeight: 540)
        #endif
    }
}
