//
//  AuthManager.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import CSUSTKit
import Foundation

@MainActor
class AuthManager: ObservableObject {
    public static let shared = AuthManager()

    @Published var ssoProfile: SSOHelper.Profile?
    @Published var isSSOLoggingIn: Bool = false
    @Published var isSSOLoggingOut: Bool = false
    var isSSOLoggedIn: Bool { return ssoProfile != nil }

    @Published var isEducationLoggingIn: Bool = false
    @Published var isShowingEducationError: Bool = false
    @Published var educationErrorMessage: String = ""

    @Published var isMoocLoggingIn: Bool = false
    @Published var isShowingMoocError: Bool = false
    @Published var moocErrorMessage: String = ""

    var ssoHelper = SSOHelper(
        mode: GlobalVars.shared.isWebVPNModeEnabled ? .webVpn : .direct,
        session: CookieHelper.shared.session
    )
    var eduHelper: EduHelper?
    var moocHelper: MoocHelper?

    private init() {
        Task {
            isSSOLoggingIn = true

            ssoProfile = try? await ssoHelper.getLoginUser()

            // If already logged in, initialize EduHelper and MoocHelper
            guard ssoProfile == nil else {
                isSSOLoggingIn = false
                loginToHelpers()
                return
            }

            guard let username = KeychainHelper.shared.ssoUsername,
                let password = KeychainHelper.shared.ssoPassword
            else {
                isSSOLoggingIn = false
                return
            }
            try? await login(username: username, password: password)
        }
    }

    func login(username: String, password: String) async throws {
        guard ssoProfile == nil else { return }

        isSSOLoggingIn = true
        defer {
            isSSOLoggingIn = false
        }
        try await ssoHelper.login(username: username, password: password)

        KeychainHelper.shared.ssoUsername = username
        KeychainHelper.shared.ssoPassword = password

        ssoProfile = try await ssoHelper.getLoginUser()
        CookieHelper.shared.save()

        loginToHelpers()
    }

    func logout() async throws {
        guard ssoProfile != nil else { return }

        isSSOLoggingOut = true
        defer {
            isSSOLoggingOut = false
        }

        try await ssoHelper.logout()
        ssoProfile = nil

        KeychainHelper.shared.ssoUsername = nil
        KeychainHelper.shared.ssoPassword = nil

        eduHelper = nil
        moocHelper = nil
    }

    func getCaptcha() async throws -> Data {
        return try await ssoHelper.getCaptcha()
    }

    func getDynamicCode(username: String, captcha: String) async throws {
        try await ssoHelper.getDynamicCode(mobile: username, captcha: captcha)
    }

    func dynamicLogin(username: String, captcha: String, dynamicCode: String) async throws {
        guard ssoProfile == nil else { return }

        isSSOLoggingIn = true

        try await ssoHelper.dynamicLogin(username: username, dynamicCode: dynamicCode, captcha: captcha)

        ssoProfile = try await ssoHelper.getLoginUser()
        CookieHelper.shared.save()
        isSSOLoggingIn = false

        loginToHelpers()
    }

    func loginToEducation() {
        guard !isEducationLoggingIn else { return }
        eduHelper = nil
        isEducationLoggingIn = true
        Task {
            defer {
                isEducationLoggingIn = false
            }
            do {
                eduHelper = EduHelper(
                    mode: GlobalVars.shared.isWebVPNModeEnabled ? .webVpn : .direct,
                    session: try await ssoHelper.loginToEducation()
                )
                CookieHelper.shared.save()
            } catch {
                educationErrorMessage = "教务服务初始化失败: \(error.localizedDescription)"
                isShowingEducationError = true
            }
        }
    }

    func loginToMooc() {
        guard !isMoocLoggingIn else { return }
        moocHelper = nil
        isMoocLoggingIn = true
        Task {
            defer {
                isMoocLoggingIn = false
            }
            do {
                moocHelper = MoocHelper(
                    mode: GlobalVars.shared.isWebVPNModeEnabled ? .webVpn : .direct,
                    session: try await ssoHelper.loginToMooc()
                )
                CookieHelper.shared.save()
            } catch {
                moocErrorMessage = "网络课程中心服务初始化失败: \(error.localizedDescription)"
                isShowingMoocError = true
            }
        }
    }

    func loginToHelpers() {
        loginToEducation()
        loginToMooc()
    }
}
