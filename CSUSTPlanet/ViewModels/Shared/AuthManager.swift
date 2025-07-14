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
    @Published var ssoProfile: LoginUser?
    var isLoggedIn: Bool {
        return ssoProfile != nil
    }

    @Published var isSSOLoggingIn: Bool = false
    @Published var isSSOLoggingOut: Bool = false

    @Published var isEducationLoggingIn: Bool = false
    @Published var isMoocLoggingIn: Bool = false

    @Published var isShowingEducationError: Bool = false
    @Published var educationErrorMessage: String = ""

    @Published var isShowingMoocError: Bool = false
    @Published var moocErrorMessage: String = ""

    var ssoHelper = SSOHelper(cookieStorage: KeychainCookieStorage())
    var eduHelper: EduHelper?
    var moocHelper: MoocHelper?

    init() {
        Task {
            isSSOLoggingIn = true

            ssoHelper.restoreCookies()
            ssoProfile = try? await ssoHelper.getLoginUser()

            // If already logged in, initialize EduHelper and MoocHelper
            guard ssoProfile == nil else {
                isSSOLoggingIn = false
                loginToHelpers()
                return
            }

            guard let username = KeychainHelper.retrieve(key: "SSOUsername"),
                  let password = KeychainHelper.retrieve(key: "SSOPassword")
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
        try await ssoHelper.login(username: username, password: password)

        _ = KeychainHelper.save(key: "SSOUsername", value: username)
        _ = KeychainHelper.save(key: "SSOPassword", value: password)

        ssoProfile = try await ssoHelper.getLoginUser()
        ssoHelper.saveCookies()
        isSSOLoggingIn = false

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

        _ = KeychainHelper.delete(key: "SSOUsername")
        _ = KeychainHelper.delete(key: "SSOPassword")

        ssoHelper.clearCookies()
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
        ssoHelper.saveCookies()
        isSSOLoggingIn = false

        loginToHelpers()
    }

    func loginToEducation() {
        guard eduHelper == nil else { return }

        isEducationLoggingIn = true
        Task {
            defer {
                isEducationLoggingIn = false
            }
            do {
                let eduSession = try await ssoHelper.loginToEducation()
                eduHelper = EduHelper(session: eduSession)
            } catch {
                educationErrorMessage = "教务服务初始化失败: \(error.localizedDescription)"
                isShowingEducationError = true
            }
        }
    }

    func loginToMooc() {
        guard moocHelper == nil else { return }
        isMoocLoggingIn = true
        Task {
            defer {
                isMoocLoggingIn = false
            }
            do {
                let moocSession = try await ssoHelper.loginToMooc()
                moocHelper = MoocHelper(session: moocSession)
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
