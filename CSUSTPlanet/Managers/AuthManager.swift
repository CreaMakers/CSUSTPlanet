//
//  AuthManager.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import Alamofire
import CSUSTKit
import Combine
import Foundation
import OSLog

@MainActor
@Observable
final class AuthManager {
    static let shared = AuthManager()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - SSO Properties

    var ssoProfile: SSOHelper.Profile?
    var isSSOLoggingIn: Bool = false
    var isSSOLoggingOut: Bool = false
    var isSSOInfoPresented: Bool = false
    var isSSOErrorPresented: Bool = false
    var ssoInfo: String = ""
    var ssoError: String = ""
    var isSSOLoggedIn: Bool { return ssoProfile != nil }

    // MARK: - Education Properties

    var isEducationLoggingIn: Bool = false
    var isEducationInfoPresented: Bool = false
    var isEducationErrorPresented: Bool = false
    var educationInfo: String = ""
    var educationError: String = ""

    // MARK: - Mooc Properties

    var isMoocLoggingIn: Bool = false
    var isMoocInfoPresented: Bool = false
    var isMoocErrorPresented: Bool = false
    var moocInfo: String = ""
    var moocError: String = ""

    // MARK: - Campus Card Properties

    var isCampusCardLoggingIn: Bool = false
    var isCampusCardInfoPresented: Bool = false
    var isCampusCardErrorPresented: Bool = false
    var campusCardInfo: String = ""
    var campusCardError: String = ""

    // MARK: - Captcha Properties

    var isCaptchaPresented: Bool = false {
        didSet {
            if oldValue == true && isCaptchaPresented == false {
                captchaContinuation?.resume()
                captchaContinuation = nil
            }
        }
    }
    var captchaImageData: Data?
    var captcha: String = ""
    @ObservationIgnored private var captchaContinuation: CheckedContinuation<Void, Never>?

    // MARK: - Helpers

    private(set) var ssoHelper: SSOHelper
    private(set) var eduHelper: EduHelper
    private(set) var moocHelper: MoocHelper
    private(set) var campusCardHelper: CampusCardHelper

    let mode: ConnectionMode = GlobalManager.shared.isWebVPNModeEnabled ? .webVpn : .direct
    private let session: Session = CookieHelper.shared.session

    @ObservationIgnored private var ssoLoginTask: Task<Void, Error>?
    @ObservationIgnored private var eduLoginTask: Task<Void, Error>?
    @ObservationIgnored private var moocLoginTask: Task<Void, Error>?
    @ObservationIgnored private var campusCardLoginTask: Task<Void, Error>?

    // MARK: - Initializer

    private init() {
        ssoHelper = SSOHelper(mode: mode, session: session)
        eduHelper = EduHelper(mode: mode, session: session)
        moocHelper = MoocHelper(mode: mode, session: session)
        campusCardHelper = CampusCardHelper(mode: mode, session: session)
        campusCardHelper.token = KeychainUtil.campusCardToken
        startObservingLifecycle()
        ssoRelogin(isSilent: true)
    }

    private func startObservingLifecycle() {
        LifecycleManager.shared.events
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .didBecomeActive(let resumeAfter):
                    let threshold: TimeInterval = 20 * 60
                    guard let resumeAfter else { return }
                    if resumeAfter > threshold {
                        Logger.authManager.debug("App后台停留时间 (\(resumeAfter)s) 超过阈值，执行重新登录")
                        ssoRelogin(isSilent: true)
                    } else {
                        Logger.authManager.debug("App后台停留时间 (\(resumeAfter)s) 不足 \(threshold)s，跳过")
                    }
                case .didBecomeInactive, .didEnterBackground:
                    break
                }
            }
            .store(in: &cancellables)
    }

    private func waitForCaptchaInput() async {
        if let existingContinuation = captchaContinuation {
            existingContinuation.resume()
            captchaContinuation = nil
        }

        return await withCheckedContinuation { newContinuation in
            self.captcha = ""
            self.captchaContinuation = newContinuation
            self.isCaptchaPresented = true
        }
    }

    // MARK: - SSO Login

    func ssoGetLoginForm() async throws -> SSOHelper.LoginForm {
        return try await ssoHelper.getLoginForm()
    }

    func ssoCheckNeedCaptcha(username: String) async throws -> Bool {
        return try await ssoHelper.checkNeedCaptcha(username: username)
    }

    func ssoGetCaptcha() async throws -> Data {
        return try await ssoHelper.getCaptcha()
    }

    func ssoRefreshCaptcha() async throws {
        captchaImageData = try await ssoHelper.getCaptcha()
    }

    // 用于登录界面的ViewModel调用
    func ssoLogin(loginForm: SSOHelper.LoginForm, username: String, password: String, captcha: String?) async throws {
        guard !isSSOLoggedIn else { return }
        isSSOLoggingIn = true
        defer { isSSOLoggingIn = false }

        try await ssoHelper.login(loginForm: loginForm, username: username, password: password, captcha: captcha)
        saveCredentials(credentials: (username, password))

        let profile = try await ssoHelper.getLoginUser()
        updateLocalProfile(with: profile)

        ssoInfo = "统一身份认证登录成功"
        isSSOInfoPresented = true

        allLogin(isSilent: false)
    }

    func ssoLogout() {
        guard isSSOLoggedIn else { return }
        Task {
            isSSOLoggingOut = true
            defer { isSSOLoggingOut = false }

            try? await eduHelper.authService.logout()
            try? await moocHelper.logout()
            try? await campusCardHelper.logout()
            try? await ssoHelper.logout()
            CookieHelper.shared.save()
            saveCredentials(credentials: nil)
            MMKVHelper.Track.userId = nil
            TrackHelper.shared.updateUserID(nil)
            ssoProfile = nil
        }
    }

    func ssoBrowserLogin(username: String, password: String, shouldPersistCredentials: Bool, cookies: [HTTPCookie]) async throws {
        CookieHelper.shared.updateCookies(cookies)

        let profile = try await ssoHelper.getLoginUser()
        updateLocalProfile(with: profile)

        ssoInfo = "统一身份认证登录成功"
        isSSOInfoPresented = true
        allLogin(isSilent: false)

        if shouldPersistCredentials {
            saveCredentials(credentials: (username, password))
        }
    }

    // MARK: - SSO Relogin Async

    func ssoReloginAsync(isSilent: Bool) async throws {
        if let task = ssoLoginTask {
            return try await task.value
        }

        let task = Task { @MainActor in
            isSSOLoggingIn = true
            defer { isSSOLoggingIn = false }

            if let ssoProfile = try? await ssoHelper.getLoginUser() {
                Logger.authManager.debug("ssoRelogin: 统一身份认证已登录，无需再登录")
                updateLocalProfile(with: ssoProfile)

                if !isSilent {
                    ssoInfo = "统一身份认证已登录"
                    isSSOInfoPresented = true
                }
                return
            }

            guard let username = KeychainUtil.ssoUsername, let password = KeychainUtil.ssoPassword else {
                Logger.authManager.debug("ssoRelogin: 统一身份认证未登录，密码未保存")
                throw SSOHelper.SSOHelperError.notLoggedIn
            }

            do {
                let loginForm = try await ssoGetLoginForm()
                let isNeedCaptcha = try await ssoCheckNeedCaptcha(username: username)
                if isNeedCaptcha {
                    try await ssoRefreshCaptcha()
                    isCaptchaPresented = true
                    await waitForCaptchaInput()
                }
                try await ssoHelper.login(loginForm: loginForm, username: username, password: password, captcha: captcha)
            } catch {
                Logger.authManager.error("ssoRelogin: 统一身份认证登录失败, \(error)")

                if !isSilent {
                    ssoError = "统一身份认证登录错误"
                    isSSOErrorPresented = true
                }
                throw error
            }

            if let ssoProfile = try? await ssoHelper.getLoginUser() {
                Logger.authManager.debug("ssoRelogin: 验证统一身份认证登录成功")
                updateLocalProfile(with: ssoProfile)

                if !isSilent {
                    ssoInfo = "统一身份认证登录成功"
                    isSSOInfoPresented = true
                }
            } else {
                Logger.authManager.debug("ssoRelogin: 验证统一身份认证登录失败")

                if !isSilent {
                    ssoError = "统一身份认证登录错误"
                    isSSOErrorPresented = true
                }
                throw SSOHelper.SSOHelperError.notLoggedIn
            }
        }

        ssoLoginTask = task
        defer { ssoLoginTask = nil }
        try await task.value
    }

    // MARK: - Education Login Async

    func educationLoginAsync(isSilent: Bool) async throws {
        if let task = eduLoginTask {
            return try await task.value
        }

        let task = Task { @MainActor in
            isEducationLoggingIn = true
            defer { isEducationLoggingIn = false }

            let tempEduHelper = EduHelper(mode: mode, session: session)
            if await tempEduHelper.isLoggedIn() {
                Logger.authManager.debug("educationLogin: 教务系统已登录")
                self.eduHelper = tempEduHelper

                if !isSilent {
                    educationInfo = "教务系统已登录"
                    isEducationInfoPresented = true
                }
                return
            }

            do {
                _ = try await ssoHelper.loginToEducation()
            } catch {
                Logger.authManager.error("educationLogin: 教务登录请求失败, \(error)")

                if !isSilent {
                    educationError = "教务登录错误"
                    isEducationErrorPresented = true
                }
                throw error
            }

            if await tempEduHelper.isLoggedIn() {
                Logger.authManager.debug("educationLogin: 验证教务登录成功")
                self.eduHelper = tempEduHelper
                CookieHelper.shared.save()

                if !isSilent {
                    educationInfo = "教务系统登录成功"
                    isEducationInfoPresented = true
                }
            } else {
                Logger.authManager.debug("educationLogin: 验证教务登录失败")

                if !isSilent {
                    educationError = "教务登录错误"
                    isEducationErrorPresented = true
                }
                throw EduHelper.EduHelperError.notLoggedIn
            }
        }

        eduLoginTask = task
        defer { eduLoginTask = nil }
        try await task.value
    }

    // MARK: - Mooc Login Async

    func moocLoginAsync(isSilent: Bool) async throws {
        if let task = moocLoginTask {
            return try await task.value
        }

        let task = Task { @MainActor in
            isMoocLoggingIn = true
            defer { isMoocLoggingIn = false }

            let tempMoocHelper = MoocHelper(mode: mode, session: session)
            if await tempMoocHelper.isLoggedIn() {
                Logger.authManager.debug("moocLogin: 网络课程平台已登录")
                self.moocHelper = tempMoocHelper

                if !isSilent {
                    moocInfo = "网络课程平台已登录"
                    isMoocInfoPresented = true
                }
                return
            }

            do {
                _ = try await ssoHelper.loginToMooc()
            } catch {
                Logger.authManager.error("moocLogin: 网络课程平台登录请求失败, \(error)")

                if !isSilent {
                    moocError = "网络课程中心登录错误"
                    isMoocErrorPresented = true
                }
                throw error
            }

            if await tempMoocHelper.isLoggedIn() {
                Logger.authManager.debug("moocLogin: 验证网络课程平台登录成功")
                self.moocHelper = tempMoocHelper
                CookieHelper.shared.save()

                if !isSilent {
                    moocInfo = "网络课程平台登录成功"
                    isMoocInfoPresented = true
                }
            } else {
                Logger.authManager.debug("moocLogin: 验证网络课程平台登录失败")

                if !isSilent {
                    moocError = "网络课程中心登录错误"
                    isMoocErrorPresented = true
                }
                throw MoocHelper.MoocHelperError.notLoggedIn
            }
        }

        moocLoginTask = task
        defer { moocLoginTask = nil }
        try await task.value
    }

    // MARK: - CampusCard Login Async

    func campusCardLoginAsync(isSilent: Bool) async throws {
        if let task = campusCardLoginTask {
            return try await task.value
        }

        let task = Task { @MainActor in
            isCampusCardLoggingIn = true
            defer { isCampusCardLoggingIn = false }

            // Keep the helper instance stable because in-flight requests may retain this reference
            // while an authentication retry refreshes the token.
            campusCardHelper.token = KeychainUtil.campusCardToken
            if await campusCardHelper.isLoggedIn() {
                Logger.authManager.debug("campusCardLogin: 教务系统已登录")

                if !isSilent {
                    campusCardInfo = "校园卡系统已登录"
                    isCampusCardInfoPresented = true
                }
                return
            }

            do {
                let (_, ticket) = try await ssoHelper.loginToCampusCard()
                try await campusCardHelper.syncToken(ticket: ticket)
            } catch {
                Logger.authManager.error("campusCardLogin: 校园卡登录请求失败, \(error)")

                if !isSilent {
                    campusCardError = "校园卡登录错误"
                    isCampusCardErrorPresented = true
                }
                throw error
            }

            if await campusCardHelper.isLoggedIn() {
                Logger.authManager.debug("campusCardLogin: 验证校园卡登录成功")
                KeychainUtil.campusCardToken = campusCardHelper.token
                CookieHelper.shared.save()

                if !isSilent {
                    campusCardInfo = "校园卡系统登录成功"
                    isCampusCardInfoPresented = true
                }
            } else {
                Logger.authManager.debug("campusCardLogin: 验证校园卡登录失败")

                if !isSilent {
                    campusCardError = "校园卡登录错误"
                    isCampusCardErrorPresented = true
                }
                throw CampusCardHelper.CampusCardHelperError.notLoggedIn
            }
        }

        campusCardLoginTask = task
        defer { campusCardLoginTask = nil }
        try await task.value
    }

    func allLoginAsync(isSilent: Bool) async throws {
        async let edu: () = educationLoginAsync(isSilent: isSilent)
        async let mooc: () = moocLoginAsync(isSilent: isSilent)
        async let campusCard: () = campusCardLoginAsync(isSilent: isSilent)
        _ = try await (edu, mooc, campusCard)
    }

    func allLogin(isSilent: Bool) {
        Task {
            do {
                try await allLoginAsync(isSilent: isSilent)
            } catch {
                Logger.authManager.warning("后台静默登录子系统失败: \(error)")
            }
        }
    }

    func ssoRelogin(isSilent: Bool) {
        Task {
            do {
                try await ssoReloginAsync(isSilent: isSilent)
                allLogin(isSilent: isSilent)
            } catch {
                Logger.authManager.error("ssoRelogin 失败: \(error)")
            }
        }
    }

    func educationLogin(isSilent: Bool) {
        Task {
            do {
                try await educationLoginAsync(isSilent: isSilent)
            } catch {
                Logger.authManager.error("educationLogin 失败: \(error)")
            }
        }
    }

    func moocLogin(isSilent: Bool) {
        Task {
            do {
                try await moocLoginAsync(isSilent: isSilent)
            } catch {
                Logger.authManager.error("moocLogin 失败: \(error)")
            }
        }
    }

    func campusCardLogin(isSilent: Bool) {
        Task {
            do {
                try await campusCardLoginAsync(isSilent: isSilent)
            } catch {
                Logger.authManager.error("campusCardLogin失败: \(error)")
            }
        }
    }

    private func updateLocalProfile(with profile: SSOHelper.Profile) {
        ssoProfile = profile
        MMKVHelper.Track.userId = profile.userAccount
        TrackHelper.shared.updateUserID(profile.userAccount)
        CookieHelper.shared.save()
    }

    private func saveCredentials(credentials: (username: String, password: String)?) {
        if let credentials {
            KeychainUtil.ssoUsername = credentials.username
            KeychainUtil.ssoPassword = credentials.password
        } else {
            KeychainUtil.ssoUsername = nil
            KeychainUtil.ssoPassword = nil
        }
    }
}

extension Logger {
    static let authManager = Logger(appCategory: "AuthManager")
}
