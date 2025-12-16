//
//  AuthManager.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import Alamofire
import CSUSTKit
import Foundation
import OSLog

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    // MARK: - SSO Properties

    @Published var ssoProfile: SSOHelper.Profile?
    @Published var isSSOLoggingIn: Bool = false
    @Published var isSSOLoggingOut: Bool = false
    @Published var isShowingSSOError: Bool = false
    var isSSOLoggedIn: Bool { return ssoProfile != nil }

    // MARK: - Education Properties

    @Published var isEducationLoggingIn: Bool = false
    @Published var isShowingEducationError: Bool = false

    // MARK: - MOOC Properties

    @Published var isMoocLoggingIn: Bool = false
    @Published var isShowingMoocError: Bool = false

    // MARK: - Helpers

    var ssoHelper: SSOHelper
    var eduHelper: EduHelper?
    var moocHelper: MoocHelper?

    private let mode: ConnectionMode = GlobalVars.shared.isWebVPNModeEnabled ? .webVpn : .direct
    private let session: Session = CookieHelper.shared.session

    // MARK: - Initializer

    private init() {
        ssoHelper = SSOHelper(mode: mode, session: session)
        ssoRelogin()
    }

    // MARK: - SSO Login

    // 用于登录界面的ViewModel调用
    func ssoLogin(username: String, password: String) async throws {
        guard !isSSOLoggedIn else { return }
        isSSOLoggingIn = true
        defer { isSSOLoggingIn = false }
        try await ssoHelper.login(username: username, password: password)
        KeychainHelper.shared.ssoUsername = username
        KeychainHelper.shared.ssoPassword = password
        ssoProfile = try await ssoHelper.getLoginUser()
        CookieHelper.shared.save()
        allLogin()
    }

    func ssoLogout() {
        guard isSSOLoggedIn else { return }
        Task {
            isSSOLoggingOut = true
            defer { isSSOLoggingOut = false }
            try? await ssoHelper.logout()
            CookieHelper.shared.save()
            KeychainHelper.shared.ssoUsername = nil
            KeychainHelper.shared.ssoPassword = nil

            ssoProfile = nil
            eduHelper = nil
            moocHelper = nil
        }
    }

    func ssoGetCaptcha() async throws -> Data {
        return try await ssoHelper.getCaptcha()
    }

    func ssoGetDynamicCode(username: String, captcha: String) async throws {
        try await ssoHelper.getDynamicCode(mobile: username, captcha: captcha)
    }

    func ssoDynamicLogin(username: String, captcha: String, dynamicCode: String) async throws {
        guard !isSSOLoggedIn else { return }
        isSSOLoggingIn = true
        defer { isSSOLoggingIn = false }
        try await ssoHelper.dynamicLogin(username: username, dynamicCode: dynamicCode, captcha: captcha)
        ssoProfile = try await ssoHelper.getLoginUser()
        CookieHelper.shared.save()
        allLogin()
    }

    func ssoRelogin() {
        Task {
            isSSOLoggingIn = true
            defer { isSSOLoggingIn = false }
            if let ssoProfile = try? await ssoHelper.getLoginUser() {
                self.ssoProfile = ssoProfile
                Logger.authManager.debug("ssoRelogin: 统一身份认证已登录，无需再登录")
                allLogin()
                return
            }
            guard let username = KeychainHelper.shared.ssoUsername, let password = KeychainHelper.shared.ssoPassword else {
                Logger.authManager.debug("ssoRelogin: 统一身份认证未登录，密码未保存，不操作")
                return
            }
            do {
                try await ssoHelper.login(username: username, password: password)
            } catch {
                Logger.authManager.debug("ssoRelogin: 统一身份认证登录失败")
                isShowingSSOError = true
                return
            }
            if let ssoProfile = try? await ssoHelper.getLoginUser() {
                self.ssoProfile = ssoProfile
                CookieHelper.shared.save()
                Logger.authManager.debug("ssoRelogin: 统一身份认证已登录")
                allLogin()
            } else {
                Logger.authManager.debug("ssoRelogin: 统一身份认证登录失败")
                isShowingSSOError = true
            }
        }
    }

    // MARK: - Education & Mooc Login

    func educationLogin() {
        // 这里假定统一身份认证已经登录
        guard !isEducationLoggingIn else { return }
        Task {
            isEducationLoggingIn = true
            defer { isEducationLoggingIn = false }
            let eduHelper = EduHelper(mode: mode, session: session)
            guard !(await eduHelper.isLoggedIn()) else {
                self.eduHelper = eduHelper
                Logger.authManager.debug("educationLogin: 教务系统已登录，无需再登录")
                return
            }
            do {
                _ = try await ssoHelper.loginToEducation()
            } catch {
                Logger.authManager.debug("educationLogin: 教务登录失败")
                isShowingEducationError = true
                return
            }
            Logger.authManager.debug("educationLogin: 教务登录成功")
            if await eduHelper.isLoggedIn() {
                // 教务登录成功
                self.eduHelper = eduHelper
                CookieHelper.shared.save()
                Logger.authManager.debug("educationLogin: 验证教务登录成功")
            } else {
                // 教务登录失败
                isShowingEducationError = true
                Logger.authManager.debug("educationLogin: 验证教务登录失败")
            }
        }
    }

    func moocLogin() {
        // 这里假定统一身份认证已经登录
        guard !isMoocLoggingIn else { return }
        Task {
            isMoocLoggingIn = true
            defer { isMoocLoggingIn = false }
            let moocHelper = MoocHelper(mode: mode, session: session)
            guard !(await moocHelper.isLoggedIn()) else {
                self.moocHelper = moocHelper
                Logger.authManager.debug("moocLogin: 网络课程平台已登录，无需再登录")
                return
            }
            do {
                _ = try await ssoHelper.loginToMooc()
            } catch {
                Logger.authManager.debug("moocLogin: 网络课程平台登录失败")
                isShowingMoocError = true
                return
            }
            Logger.authManager.debug("moocLogin: 网络课程平台登录成功")
            if await moocHelper.isLoggedIn() {
                // 网络课程平台登录成功
                self.moocHelper = moocHelper
                CookieHelper.shared.save()
                Logger.authManager.debug("moocLogin: 验证网络课程平台登录成功")
            } else {
                // 网络课程平台登录失败
                isShowingMoocError = true
                Logger.authManager.debug("moocLogin: 验证网络课程平台登录失败")
            }
        }
    }

    func allLogin() {
        educationLogin()
        moocLogin()
    }
}
