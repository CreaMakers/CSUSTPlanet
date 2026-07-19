//
//  SSOLoginView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import Foundation
import SwiftUI

struct SSOLoginView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var errorToast: ToastState = .errorTitle
    @Bindable private var authManager = AuthManager.shared

    var body: some View {
        SSOLoginContent(
            initialUsername: KeychainUtil.ssoUsername ?? "",
            initialPassword: KeychainUtil.ssoPassword ?? "",
            isLoggingIn: authManager.isSSOLoggingIn,
            errorToast: $errorToast,
            onLogin: login,
            onCheckNeedCaptcha: checkNeedCaptcha,
            onRefreshCaptcha: refreshCaptcha,
            onBrowserLoginSuccess: onBrowserLoginSuccess
        )
    }

    private func login(username: String, password: String, captcha: String) async {
        do {
            if (try? await AuthManager.shared.ssoHelper.getLoginUser()) != nil {
                AuthManager.shared.ssoRelogin(isSilent: false)
            } else {
                let loginForm = try await AuthManager.shared.ssoGetLoginForm()
                try await AuthManager.shared.ssoLogin(loginForm: loginForm, username: username, password: password, captcha: captcha)
            }
            dismiss()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func checkNeedCaptcha(username: String) async -> Bool {
        do {
            return try await AuthManager.shared.ssoCheckNeedCaptcha(username: username)
        } catch {
            errorToast.show(message: "检查是否需要验证码失败: \(error.localizedDescription)")
            return false
        }
    }

    private func refreshCaptcha() async -> Data? {
        do {
            return try await AuthManager.shared.ssoGetCaptcha()
        } catch {
            errorToast.show(message: error.localizedDescription)
            return nil
        }
    }

    private func onBrowserLoginSuccess(_ username: String, _ password: String, _ mode: SSOBrowserView.LoginMode, _ cookies: [HTTPCookie]) {
        Task {
            do {
                try await AuthManager.shared.ssoBrowserLogin(username: username, password: password, shouldPersistCredentials: mode == .username, cookies: cookies)
                dismiss()
            } catch {
                errorToast.show(message: "通过网页登录失败: \(error.localizedDescription)")
            }
        }
    }
}
