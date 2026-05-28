//
//  AuthManager+Retry.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/23.
//

import CSUSTKit
import OSLog

extension AuthManager: AuthRetryProvider {
    func withAuthRetry<T>(
        system: CampusSystem,
        maxRetries: Int = 2,
        operation: @MainActor @escaping () async throws -> T
    ) async throws -> T {
        var attempts = 0

        while true {
            do {
                return try await operation()
            } catch {
                attempts += 1
                let isNotLoggedIn = isNotLoggedInError(error: error, system: system)

                guard isNotLoggedIn, attempts <= maxRetries else {
                    throw error
                }

                Logger.authManager.debug("请求遭拒，触发自动重试 (\(attempts)/\(maxRetries)) - 目标系统: \(String(describing: system))")

                do {
                    try await ssoReloginAsync(isSilent: true)

                    switch system {
                    case .edu:
                        try await educationLoginAsync(isSilent: true)
                    case .mooc:
                        try await moocLoginAsync(isSilent: true)
                    case .campusCard:
                        try await campusCardLoginAsync(isSilent: true)
                    }
                } catch let loginError {
                    if isNotLoggedInError(error: loginError, system: system) {
                        Logger.authManager.debug("自动登录过程中验证未通过，交由循环进行下一轮处理")
                        continue
                    } else {
                        throw loginError
                    }
                }
            }
        }
    }

    private func isNotLoggedInError(error: Error, system: CampusSystem) -> Bool {
        switch system {
        case .edu:
            if let eduError = error as? EduHelper.EduHelperError, case .notLoggedIn = eduError {
                return true
            }
            return false
        case .mooc:
            if let moocError = error as? MoocHelper.MoocHelperError, case .notLoggedIn = moocError {
                return true
            }
            return false
        case .campusCard:
            if let campusCardError = error as? CampusCardHelper.CampusCardHelperError, case .notLoggedIn = campusCardError {
                return true
            }
            return false
        }
    }
}
