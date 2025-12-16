//
//  AuthManager.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import Alamofire
import CSUSTKit
import Foundation

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    // MARK: - SSO Properties

    @Published var ssoProfile: SSOHelper.Profile?
    @Published var isSSOLoggingIn: Bool = false
    @Published var isSSOLoggingOut: Bool = false
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
        Task {
            await initialize()
        }
    }

    private func initialize() async {
        isSSOLoggingIn = true
        defer { isSSOLoggingIn = false }
        if let ssoProfile = try? await ssoHelper.getLoginUser() {
            // 统一身份认证已登录
            self.ssoProfile = ssoProfile

            // 尝试登录教务
            Task {
                isEducationLoggingIn = true
                defer { isEducationLoggingIn = false }
                let eduHelper = EduHelper(mode: mode, session: session)
                if await eduHelper.isLoggedIn() {
                    // 教务已登录
                    self.eduHelper = eduHelper
                } else {
                    // 教务未登录，尝试登录
                    _ = try? await ssoHelper.loginToEducation()
                    if await eduHelper.isLoggedIn() {
                        // 教务登录成功
                        self.eduHelper = eduHelper
                        CookieHelper.shared.save()
                    } else {
                        // 教务登录失败
                        isShowingEducationError = true
                    }
                }
            }

            // 尝试登录网络课程平台
            Task {
                isMoocLoggingIn = true
                defer { isMoocLoggingIn = false }
                let moocHelper = MoocHelper(mode: mode, session: session)
                if await moocHelper.isLoggedIn() {
                    // 网络课程中心已登录
                    self.moocHelper = moocHelper
                    CookieHelper.shared.save()
                } else {
                    // 网络课程中心未登录，尝试登录
                    _ = try? await ssoHelper.loginToMooc()
                    if await moocHelper.isLoggedIn() {
                        // 网络课程中心登录成功
                        self.moocHelper = moocHelper
                    } else {
                        // 网络课程中心登录失败
                        isShowingMoocError = true
                    }
                }
            }
        } else {
            // 统一身份认证未登录
            if let username = KeychainHelper.shared.ssoUsername, let password = KeychainHelper.shared.ssoPassword {
                // 统一身份认证未登录，密码已保存，尝试登录
                try? await ssoHelper.login(username: username, password: password)
                if let ssoProfile = try? await ssoHelper.getLoginUser() {
                    // 统一身份认证已登录
                    self.ssoProfile = ssoProfile
                    CookieHelper.shared.save()

                    Task {
                        // 尝试登录教务
                        let eduHelper = EduHelper(mode: mode, session: session)
                        _ = try? await ssoHelper.loginToEducation()
                        if await eduHelper.isLoggedIn() {
                            // 教务登录成功
                            self.eduHelper = eduHelper
                            CookieHelper.shared.save()
                        } else {
                            // 教务登录失败
                            isShowingEducationError = true
                        }
                    }

                    Task {
                        // 尝试登录网络课程平台
                        let moocHelper = MoocHelper(mode: mode, session: session)
                        _ = try? await ssoHelper.loginToMooc()
                        if await moocHelper.isLoggedIn() {
                            // 网络课程平台登录成功
                            self.moocHelper = moocHelper
                            CookieHelper.shared.save()
                        } else {
                            // 网络课程平台登录失败
                            isShowingMoocError = true
                        }
                    }
                } else {
                    // 统一身份认证登录失败，不操作
                }
            } else {
                // 统一身份认证未登录，密码未保存，不操作
            }
        }
    }

    // MARK: - Methods

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
                isShowingMoocError = true
            }
        }
    }

    func loginToHelpers() {
        loginToEducation()
        loginToMooc()
    }
}
