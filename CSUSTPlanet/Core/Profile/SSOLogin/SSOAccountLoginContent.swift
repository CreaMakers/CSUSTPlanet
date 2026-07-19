//
//  SSOAccountLoginContent.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/7/19.
//

import Foundation
import SwiftUI

struct SSOAccountLoginContent: View {
    @State var username: String
    @State var password: String
    @State var captcha: String
    @State private var captchaImageData: Data?
    @State var isNeedCaptcha: Bool
    @State private var isPasswordVisible = false
    @FocusState private var isUsernameFocused: Bool

    let isLoggingIn: Bool
    let onLogin: (String, String, String) async -> Void
    let onCheckNeedCaptcha: (String) async -> Bool
    let onRefreshCaptcha: () async -> Data?

    var body: some View {
        Form {
            Section {
                TextField("账号", text: $username)
                    .focused($isUsernameFocused)
                    .textContentType(.username)
                    .autocorrectionDisabled(true)
                    #if os(iOS)
                .textInputAutocapitalization(.never)
                    #endif

                if isNeedCaptcha {
                    captchaInput
                }

                passwordInput
            } header: {
                Text("账号信息")
            } footer: {
                Text("如果您不记得账号或密码，可以切换到 **“网页登录”** 尝试找回。\n\n账号密码将安全地保存在您的设备本地。当登录状态失效时，程序会自动帮您重新登录，无需反复手动输入。")
            }
        }
        .onChange(of: isUsernameFocused) { _, isFocused in
            if !isFocused {
                Task { await checkNeedCaptcha() }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(asyncAction: login) {
                    HStack {
                        if isLoggingIn {
                            ProgressView().smallControlSizeOnMac()
                        } else {
                            Text("登录")
                        }
                    }
                }
                .disabled(isLoginDisabled)
            }
        }
    }

    private var captchaInput: some View {
        HStack {
            TextField("验证码", text: $captcha)
                .textContentType(.none)
                .autocorrectionDisabled()
                #if os(iOS)
            .textInputAutocapitalization(.never)
                #endif

            captchaImage
        }
    }

    @ViewBuilder
    private var captchaImage: some View {
        if let captchaImageData {
            #if os(macOS)
            if let image = NSImage(data: captchaImageData) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 28)
                    .contentShape(.rect)
                    .onTapGesture { Task { await refreshCaptcha() } }
            }
            #else
            if let image = UIImage(data: captchaImageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 28)
                    .contentShape(.rect)
                    .onTapGesture { Task { await refreshCaptcha() } }
            }
            #endif
        } else {
            ProgressView()
                .smallControlSizeOnMac()
                .frame(width: 100)
        }
    }

    private var passwordInput: some View {
        HStack {
            Group {
                if isPasswordVisible {
                    TextField("密码", text: $password)
                } else {
                    SecureField("密码", text: $password)
                        .autocorrectionDisabled(true)
                }
            }
            .textContentType(.password)

            Button(action: { isPasswordVisible.toggle() }) {
                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var isLoginDisabled: Bool {
        username.isEmpty || password.isEmpty || (isNeedCaptcha && captcha.isEmpty) || isLoggingIn
    }

    private func login() async {
        if !isNeedCaptcha, await checkNeedCaptcha() {
            return
        }
        await onLogin(username, password, captcha)
    }

    private func checkNeedCaptcha() async -> Bool {
        guard !username.isEmpty else { return false }

        let needsCaptcha = await onCheckNeedCaptcha(username)
        if needsCaptcha {
            await refreshCaptcha()
        }
        withAnimation {
            isNeedCaptcha = needsCaptcha
        }
        return needsCaptcha
    }

    private func refreshCaptcha() async {
        captchaImageData = await onRefreshCaptcha()
    }
}

#Preview("SSOAccountLoginContent") {
    NavigationStack {
        SSOAccountLoginContent(
            username: "2025000000",
            password: "password",
            captcha: "",
            isNeedCaptcha: false,
            isLoggingIn: false,
            onLogin: { _, _, _ in },
            onCheckNeedCaptcha: { _ in false },
            onRefreshCaptcha: { nil }
        )
    }
}

#Preview("SSOAccountLoginContent Captcha Loading") {
    NavigationStack {
        SSOAccountLoginContent(
            username: "2025000000",
            password: "password",
            captcha: "1234",
            isNeedCaptcha: true,
            isLoggingIn: false,
            onLogin: { _, _, _ in },
            onCheckNeedCaptcha: { _ in true },
            onRefreshCaptcha: { nil }
        )
    }
}
