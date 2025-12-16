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
                eduHelper = EduHelper(
                    mode: GlobalVars.shared.isWebVPNModeEnabled ? .webVpn : .direct,
                    session: eduSession
                )
                CookieHelper.shared.save()
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
                moocHelper = MoocHelper(
                    mode: GlobalVars.shared.isWebVPNModeEnabled ? .webVpn : .direct,
                    session: moocSession
                )
                CookieHelper.shared.save()
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
