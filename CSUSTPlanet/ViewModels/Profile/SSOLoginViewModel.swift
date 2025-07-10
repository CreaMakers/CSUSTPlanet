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

    @Published var isShowingLoginPopover: Bool {
        didSet {
            isShowingLoginPopoverBinding.wrappedValue = isShowingLoginPopover
        }
    }

    private var isShowingLoginPopoverBinding: Binding<Bool>

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
        return username.isEmpty || password.isEmpty || authManager.isLoggingIn
    }

    var isGetDynamicCodeDisabled: Bool {
        return captcha.isEmpty || username.isEmpty || countdown > 0 || authManager.isLoggingIn
    }

    var isDynamicLoginDisabled: Bool {
        return username.isEmpty || captcha.isEmpty || smsCode.isEmpty || authManager.isLoggingIn
    }

    init(authManager: AuthManager, isShowingLoginPopover: Binding<Bool>) {
        self.authManager = authManager
        self.isShowingLoginPopover = isShowingLoginPopover.wrappedValue
        self.isShowingLoginPopoverBinding = isShowingLoginPopover
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
                isShowingLoginPopover = false
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
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }

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
                isShowingLoginPopover = false
            }
        }
    }

    func closeLoginPopover() {
        isShowingLoginPopover = false
    }
}
