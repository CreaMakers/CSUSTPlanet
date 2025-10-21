//
//  NotificationHelper.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/15.
//

import Foundation
import UIKit
import UserNotifications

enum NotificationHelperError: Error, LocalizedError {
    case deviceTokenTimeout
    case failedToRegister(Error?)
    case authorizationDenied

    var errorDescription: String? {
        switch self {
        case .deviceTokenTimeout:
            return "获取设备令牌超时"
        case .failedToRegister(let error):
            return "注册远程通知失败: \(error?.localizedDescription ?? "未知错误")"
        case .authorizationDenied:
            return "用户拒绝了通知权限"
        }
    }
}

class NotificationHelper {
    static let shared = NotificationHelper()

    var token: Data?

    private var tokenContinuation: CheckedContinuation<Data, Error>? = nil

    private init() {}

    func setup() {
        // 静默获取设备令牌
        Task {
            guard MMKVManager.shared.isElectricityTermAccepted else { return }
            guard await hasAuthorization() else { return }
            guard let token = try? await getToken() else { return }
            self.token = token
            debugPrint("Device Token obtained silently: \(token)")
        }
    }

    func getToken() async throws -> Data {
        if let token = token { return token }

        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        guard try await UNUserNotificationCenter.current().requestAuthorization(options: options) else {
            throw NotificationHelperError.authorizationDenied
        }

        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.tokenContinuation = continuation
            Task {
                try await Task.sleep(nanoseconds: 10 * 1_000_000_000)  // 10 seconds timeout
                if let continuation = self.tokenContinuation {
                    continuation.resume(throwing: NotificationHelperError.deviceTokenTimeout)
                }
            }
        }
    }

    func hasAuthorization() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    func handleNotificationRegistration(token: Data?, error: Error?) {
        guard let tokenContinuation = tokenContinuation else { return }
        guard let token = token else {
            tokenContinuation.resume(throwing: NotificationHelperError.failedToRegister(error))
            return
        }
        tokenContinuation.resume(returning: token)
        self.tokenContinuation = nil
        self.token = token
    }
}

extension Data {
    var hexString: String {
        self.map { String(format: "%02.2hhx", $0) }.joined()
    }
}
