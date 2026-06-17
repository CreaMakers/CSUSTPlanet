//
//  SSOLoginView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import SwiftUI

struct SSOLoginView: View {
    @Environment(\.dismiss) private var dismiss

    @State var viewModel = SSOLoginViewModel()
    @Bindable var authManager = AuthManager.shared
    @FocusState private var isUsernameFocused: Bool

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                #if os(iOS)
                TabView(selection: $viewModel.selectedTab) {
                    Form {
                        accountLoginSection
                    }
                    .tag(SSOLoginViewModel.LoginTab.account)

                    webLoginSection.tag(SSOLoginViewModel.LoginTab.web)
                }
                .tabViewStyle(.page)
                #elseif os(macOS)
                NavigationSplitView {
                    List(selection: $viewModel.selectedTab) {
                        Label("账号登录", systemImage: "person").tag(SSOLoginViewModel.LoginTab.account)
                        Label("网页登录", systemImage: "globe").tag(SSOLoginViewModel.LoginTab.web)
                    }
                } detail: {
                    switch viewModel.selectedTab {
                    case .account:
                        Form { accountLoginSection }
                    case .web:
                        webLoginSection
                    }
                }
                #endif
            }
            .formStyle(.grouped)
            .onChange(of: isUsernameFocused) { _, newValue in
                if !newValue {
                    Task { await viewModel.checkNeedCaptcha() }
                }
            }
            #if os(iOS)
            .navigationTitle("统一身份认证登录")
            .inlineToolbarTitle()
            .background(Color(PlatformColor.systemGroupedBackground))
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .principal) {
                    Picker("登录方式", selection: $viewModel.selectedTab) {
                        Text("账号登录").tag(SSOLoginViewModel.LoginTab.account)
                        Text("网页登录").tag(SSOLoginViewModel.LoginTab.web)
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
                ToolbarItem(placement: .primaryAction) {
                    let disabled =
                        if viewModel.selectedTab == .account {
                            if viewModel.isNeedCaptcha {
                                viewModel.username.isEmpty || viewModel.password.isEmpty || viewModel.captcha.isEmpty || AuthManager.shared.isSSOLoggingIn
                            } else {
                                viewModel.username.isEmpty || viewModel.password.isEmpty || AuthManager.shared.isSSOLoggingIn
                            }
                        } else {
                            true
                        }

                    Button(asyncAction: { await viewModel.login { dismiss() } }) {
                        HStack {
                            Text("登录")
                            if authManager.isSSOLoggingIn {
                                ProgressView().smallControlSizeOnMac()
                            }
                        }
                    }
                    .disabled(disabled)
                }
            }
            .errorToast($viewModel.errorToast)
        }
        #if os(macOS)
        .frame(minWidth: 720, minHeight: 540)
        #endif
    }

    // MARK: - Account Login Section

    @ViewBuilder
    private var accountLoginSection: some View {
        Section {
            TextField("账号", text: $viewModel.username)
                .focused($isUsernameFocused)
                .textContentType(.username)
                .autocorrectionDisabled(true)
                #if os(iOS)
            .textInputAutocapitalization(.never)
                #endif

            if viewModel.isNeedCaptcha {
                HStack {
                    TextField("验证码", text: $viewModel.captcha)
                        .textContentType(.none)
                        .autocorrectionDisabled()
                        #if os(iOS)
                    .textInputAutocapitalization(.never)
                        #endif

                    if let data = viewModel.captchaImageData {
                        #if os(macOS)
                        if let nsImage = NSImage(data: data) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 28)
                                .contentShape(.rect)
                                .onTapGesture { Task { await viewModel.refreshCaptcha() } }
                        }
                        #else
                        if let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 28)
                                .contentShape(.rect)
                                .onTapGesture { Task { await viewModel.refreshCaptcha() } }
                        }
                        #endif
                    } else {
                        ProgressView()
                            .smallControlSizeOnMac()
                            .frame(width: 100)
                    }
                }
            }

            HStack {
                Group {
                    if viewModel.isPasswordVisible {
                        TextField("密码", text: $viewModel.password)
                    } else {
                        SecureField("密码", text: $viewModel.password)
                            .autocorrectionDisabled(true)
                    }
                }
                .textContentType(.password)

                Button(action: { viewModel.isPasswordVisible.toggle() }) {
                    Image(systemName: viewModel.isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("账号信息")
        } footer: {
            Text("如果您不记得账号或密码，可以切换到 **“网页登录”** 尝试找回。\n\n账号密码将安全地保存在您的设备本地。当登录状态失效时，程序会自动帮您重新登录，无需反复手动输入。")
        }
    }

    // MARK: - Web Login Section

    @ViewBuilder
    private var webLoginSection: some View {
        SSOBrowserView { username, password, loginMode, cookies in
            viewModel.onBrowserLoginSuccess(username, password, loginMode, cookies) {
                dismiss()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
