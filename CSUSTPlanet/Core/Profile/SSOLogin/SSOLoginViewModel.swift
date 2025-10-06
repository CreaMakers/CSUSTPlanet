//
//  SSOLoginViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/10.
//

import Foundation
import SwiftUI

@MainActor
class SSOLoginViewModel: ObservableObject {
    private var authManager: AuthManager

    @Published var isShowingLoginSheet: Bool {
        didSet {
            isShowingLoginSheetBinding.wrappedValue = isShowingLoginSheet
        }
    }

    private var isShowingLoginSheetBinding: Binding<Bool>

    @Published var selectedTab = 0

    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isPasswordVisible: Bool = false

    @Published var captchaImageData: Data? = nil
    @Published var captcha: String = ""
    @Published var smsCode: String = ""

    @Published var isShowingError: Bool = false
    @Published var errorMessage: String = ""

    @Published var countdown = 0

    var isAccountLoginDisabled: Bool {
        return username.isEmpty || password.isEmpty || authManager.isSSOLoggingIn
    }

    var isGetDynamicCodeDisabled: Bool {
        return captcha.isEmpty || username.isEmpty || countdown > 0 || authManager.isSSOLoggingIn
    }

    var isDynamicLoginDisabled: Bool {
        return username.isEmpty || captcha.isEmpty || smsCode.isEmpty || authManager.isSSOLoggingIn
    }

    init(authManager: AuthManager, isShowingLoginSheet: Binding<Bool>) {
        self.authManager = authManager
        self.isShowingLoginSheet = isShowingLoginSheet.wrappedValue
        self.isShowingLoginSheetBinding = isShowingLoginSheet
    }

    func handleAccountLogin() {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "请输入用户名或密码"
            isShowingError = true
            return
        }

        Task {
            do {
                try await authManager.login(username: username, password: password)
                isShowingLoginSheet = false
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func handleGetDynamicCode() {
        guard !username.isEmpty, !captcha.isEmpty else {
            errorMessage = "请输入用户名和验证码"
            isShowingError = true
            return
        }

        Task {
            do {
                try await authManager.getDynamicCode(username: username, captcha: captcha)

                countdown = 120
                Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                    Task { @MainActor in
                        guard let self = self else {
                            timer.invalidate()
                            return
                        }
                        if self.countdown > 1 {
                            self.countdown -= 1
                        } else {
                            timer.invalidate()
                            self.countdown = 0
                        }
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func handleRefreshCaptcha() {
        Task {
            do {
                captchaImageData = try await authManager.getCaptcha()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func handleDynamicLogin() {
        Task {
            do {
                try await authManager.dynamicLogin(username: username, captcha: captcha, dynamicCode: smsCode)
                isShowingLoginSheet = false
            }
        }
    }

    func closeLoginSheet() {
        isShowingLoginSheet = false
    }
}
