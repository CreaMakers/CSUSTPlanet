//
//  UserManager.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import CSUSTKit
import Foundation

@MainActor
class UserManager: ObservableObject {
    @Published var user: LoginUser?

    @Published var isLoggingIn: Bool = false
    @Published var isLoggingOut: Bool = false

    @Published var eduProfile: Profile?
    @Published var isEduProfileLoading: Bool = false

    @Published var moocProfile: MoocProfile?
    @Published var isMoocProfileLoading: Bool = false

    private var ssoHelper = SSOHelper(cookieStorage: KeychainCookieStorage())
    private var eduHelper: EduHelper?
    private var moocHelper: MoocHelper?

    init() {
        Task {
            await loadUser()
        }
    }

    func loadEduProfile() async throws {
        isEduProfileLoading = true
        defer {
            isEduProfileLoading = false
        }

        guard eduProfile == nil else { return }
        if eduHelper == nil {
            eduHelper = try EduHelper(session: await ssoHelper.loginToEducation())
        }
        guard let eduHelper = eduHelper else {
            return
        }
        eduProfile = try await eduHelper.profileService.getProfile()
    }

    func loadMoocProfile() async throws {
        isMoocProfileLoading = true
        defer {
            isMoocProfileLoading = false
        }

        guard moocProfile == nil else { return }
        if moocHelper == nil {
            moocHelper = try MoocHelper(session: await ssoHelper.loginToMooc())
        }
        guard let moocHelper = moocHelper else {
            return
        }
        moocProfile = try await moocHelper.getProfile()
    }

    func loadUser() async {
        ssoHelper.restoreCookies()
        user = try? await ssoHelper.getLoginUser()

        guard user == nil else {
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

    func login(username: String, password: String) async throws {
        guard user == nil else { return }

        isLoggingIn = true
        defer {
            isLoggingIn = false
        }

        try await ssoHelper.login(username: username, password: password)

        _ = KeychainHelper.save(key: "SSOUsername", value: username)
        _ = KeychainHelper.save(key: "SSOPassword", value: password)

        user = try await ssoHelper.getLoginUser()
        ssoHelper.saveCookies()

        eduHelper = try EduHelper(session: await ssoHelper.loginToEducation())
        moocHelper = try MoocHelper(session: await ssoHelper.loginToMooc())
    }

    func logout() async throws {
        guard user != nil else { return }

        isLoggingOut = true
        defer {
            isLoggingOut = false
        }

        try await ssoHelper.logout()
        user = nil

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
        guard user == nil else { return }

        isLoggingIn = true
        defer {
            isLoggingIn = false
        }

        try await ssoHelper.dynamicLogin(username: username, dynamicCode: dynamicCode, captcha: captcha)

        user = try await ssoHelper.getLoginUser()
        ssoHelper.saveCookies()

        eduHelper = try EduHelper(session: await ssoHelper.loginToEducation())
        moocHelper = try MoocHelper(session: await ssoHelper.loginToMooc())
    }

    func clearCache() {
        _ = KeychainHelper.delete(key: "SSOUsername")
        _ = KeychainHelper.delete(key: "SSOPassword")

        ssoHelper.clearCookies()

        user = nil

        eduProfile = nil
        eduHelper = nil

        moocProfile = nil
        moocHelper = nil
    }
}
