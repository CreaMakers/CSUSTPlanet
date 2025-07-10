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

    @Published var isLoggingIn: Bool = false
    @Published var isLoggingOut: Bool = false

    var ssoHelper = SSOHelper(cookieStorage: KeychainCookieStorage())
    var eduHelper: EduHelper?
    var moocHelper: MoocHelper?

    static let shared = AuthManager()

    private init() {
        Task {
            isLoggingIn = true
            defer {
                isLoggingIn = false
            }

            ssoHelper.restoreCookies()
            ssoProfile = try? await ssoHelper.getLoginUser()

            guard ssoProfile == nil else {
                eduHelper = try? EduHelper(session: await ssoHelper.loginToEducation())
                moocHelper = try? MoocHelper(session: await ssoHelper.loginToMooc())
                return
            }

            guard let username = KeychainHelper.retrieve(key: "SSOUsername"),
                  let password = KeychainHelper.retrieve(key: "SSOPassword")
            else {
                return
            }
            try? await login(username: username, password: password)
        }
    }

    func login(username: String, password: String) async throws {
        guard ssoProfile == nil else { return }

        isLoggingIn = true
        defer {
            isLoggingIn = false
        }

        try await ssoHelper.login(username: username, password: password)

        _ = KeychainHelper.save(key: "SSOUsername", value: username)
        _ = KeychainHelper.save(key: "SSOPassword", value: password)

        ssoProfile = try await ssoHelper.getLoginUser()
        ssoHelper.saveCookies()

        eduHelper = try EduHelper(session: await ssoHelper.loginToEducation())
        moocHelper = try MoocHelper(session: await ssoHelper.loginToMooc())
    }

    func logout() async throws {
        guard ssoProfile != nil else { return }

        isLoggingOut = true
        defer {
            isLoggingOut = false
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

        isLoggingIn = true
        defer {
            isLoggingIn = false
        }

        try await ssoHelper.dynamicLogin(username: username, dynamicCode: dynamicCode, captcha: captcha)

        ssoProfile = try await ssoHelper.getLoginUser()
        ssoHelper.saveCookies()

        eduHelper = try EduHelper(session: await ssoHelper.loginToEducation())
        moocHelper = try MoocHelper(session: await ssoHelper.loginToMooc())
    }

    func clearCache() {
        _ = KeychainHelper.delete(key: "SSOUsername")
        _ = KeychainHelper.delete(key: "SSOPassword")

        ssoHelper.clearCookies()

        ssoProfile = nil

        eduHelper = nil
        moocHelper = nil
    }
}
