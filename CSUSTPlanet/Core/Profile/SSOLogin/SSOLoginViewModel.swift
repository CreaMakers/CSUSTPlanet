//
//  SSOLoginViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/10.
//

import CSUSTKit
import Foundation
import SwiftUI

@MainActor
@Observable
class SSOLoginViewModel {
    enum LoginTab: Hashable {
        case account
        case web
    }

    var selectedTab: LoginTab? = .account

    var username: String = KeychainUtil.ssoUsername ?? ""
    var password: String = KeychainUtil.ssoPassword ?? ""
    var captcha: String = ""

    var isNeedCaptcha: Bool = false
    var isPasswordVisible: Bool = false

    var captchaImageData: Data? = nil

    var errorToast: ToastState = .errorTitle

    func login(_ done: () -> Void) async {
        do {
            if (try? await AuthManager.shared.ssoHelper.getLoginUser()) != nil {
                AuthManager.shared.ssoRelogin(isSilent: false)
            } else {
                if !isNeedCaptcha, await checkNeedCaptcha() {
                    return
                }

                let loginForm = try await AuthManager.shared.ssoGetLoginForm()
                try await AuthManager.shared.ssoLogin(loginForm: loginForm, username: username, password: password, captcha: captcha)
            }
            done()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func checkNeedCaptcha() async -> Bool {
        guard !username.isEmpty else { return false }
        do {
            let isNeedCaptcha = try await AuthManager.shared.ssoCheckNeedCaptcha(username: username)
            if isNeedCaptcha {
                await refreshCaptcha()
            }
            withAnimation { self.isNeedCaptcha = isNeedCaptcha }
            return isNeedCaptcha
        } catch {
            errorToast.show(message: "检查是否需要验证码失败: \(error.localizedDescription)")
        }
        return false
    }

    func refreshCaptcha() async {
        do {
            captchaImageData = try await AuthManager.shared.ssoGetCaptcha()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func onBrowserLoginSuccess(_ username: String, _ password: String, _ mode: SSOBrowserView.LoginMode, _ cookies: [HTTPCookie], _ done: @escaping () -> Void) {
        Task {
            do {
                try await AuthManager.shared.ssoBrowserLogin(username: username, password: password, shouldPersistCredentials: mode == .username, cookies: cookies)
                done()
            } catch {
                errorToast.show(message: "通过网页登录失败: \(error.localizedDescription)")
            }
        }
    }
}
