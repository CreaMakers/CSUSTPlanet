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

    private var eduLoginTask: Task<Void, Error>?
    var eduLoginID = UUID()
    private var moocLoginTask: Task<Void, Error>?
    var moocLoginID = UUID()

    var ssoHelper = SSOHelper(cookieStorage: KeychainCookieStorage())
    var eduHelper: EduHelper?
    var moocHelper: MoocHelper?

    private init() {
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
        defer {
            isSSOLoggingIn = false
        }
        try await ssoHelper.login(username: username, password: password)

        KeychainHelper.save(key: "SSOUsername", value: username)
        KeychainHelper.save(key: "SSOPassword", value: password)

        ssoProfile = try await ssoHelper.getLoginUser()
        ssoHelper.saveCookies()

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

        KeychainHelper.delete(key: "SSOUsername")
        KeychainHelper.delete(key: "SSOPassword")

        ssoHelper.clearCookies()

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
        ssoHelper.saveCookies()
        isSSOLoggingIn = false

        loginToHelpers()
    }

    func loginToEducation() {
        let isAlreadyLoggingIn = eduLoginTask != nil
        eduHelper = nil
        eduLoginTask?.cancel()
        eduLoginID = UUID()

        if !isAlreadyLoggingIn {
            isEducationLoggingIn = true
        }
        eduLoginTask = Task {
            defer {
                if !Task.isCancelled {
                    isEducationLoggingIn = false
                    eduLoginTask = nil
                }
            }
            do {
                let eduSession = try await ssoHelper.loginToEducation()
                // #if DEBUG
                //     try await Task.sleep(nanoseconds: 5_000_000_000)
                // #endif
                if Task.isCancelled { return }
                eduHelper = EduHelper(session: eduSession)
            } catch {
                if !Task.isCancelled && !(error is CancellationError) {
                    educationErrorMessage = "教务服务初始化失败: \(error.localizedDescription)"
                    isShowingEducationError = true
                }
            }
        }
    }

    func loginToMooc() {
        let isAlreadyLoggingIn = moocLoginTask != nil
        moocHelper = nil
        moocLoginTask?.cancel()
        moocLoginID = UUID()

        if !isAlreadyLoggingIn {
            isMoocLoggingIn = true
        }
        moocLoginTask = Task {
            defer {
                if !Task.isCancelled {
                    isMoocLoggingIn = false
                    moocLoginTask = nil
                }
            }
            do {
                let moocSession = try await ssoHelper.loginToMooc()
                // #if DEBUG
                //     try await Task.sleep(nanoseconds: 5_000_000_000)
                // #endif
                if Task.isCancelled { return }
                moocHelper = MoocHelper(session: moocSession)
            } catch {
                if !Task.isCancelled && !(error is CancellationError) {
                    moocErrorMessage = "网络课程中心服务初始化失败: \(error.localizedDescription)"
                    isShowingMoocError = true
                }
            }
        }
    }

    func loginToHelpers() {
        loginToEducation()
        loginToMooc()
    }
}
