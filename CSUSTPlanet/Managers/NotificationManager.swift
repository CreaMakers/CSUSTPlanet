//
//  NotificationManager.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/15.
//

import Foundation
import OSLog
import UIKit
import UserNotifications

enum NotificationManagerError: Error, LocalizedError {
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

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    var token: Data?
    private var tokenContinuation: CheckedContinuation<Data, Error>? = nil

    @Published var isShowingError: Bool = false
    @Published var errorDescription: String = ""

    private init() {}

    func setup() {
        // 静默获取设备令牌
        Task {
            Logger.notificationManager.debug("开始静默获取设备令牌")
            guard await hasAuthorization() else {
                Logger.notificationManager.debug("无通知权限，关闭通知开关")
                GlobalManager.shared.isNotificationEnabled = false
                return
            }
            do {
                self.token = try await getToken()
            } catch NotificationManagerError.authorizationDenied {
                Logger.notificationManager.debug("无通知令牌权限，关闭通知开关")
                GlobalManager.shared.isNotificationEnabled = false
                return
            } catch {
                Logger.notificationManager.debug("其他原因无法获取到通知令牌，结束操作: \(error)")
                return
            }
            Logger.notificationManager.debug("静默获取设备令牌成功，开始同步")
            syncAll()
        }
    }

    func syncAll() {
        Task { await ElectricityBindingUtil.sync() }
    }

    func toggle() {
        Task {
            if GlobalManager.shared.isNotificationEnabled {
                guard await hasAuthorization() else {
                    GlobalManager.shared.isNotificationEnabled = false
                    self.errorDescription = "未开启系统通知权限，无法开启通知功能"
                    self.isShowingError = true
                    return
                }
                syncAll()
            } else {
                syncAll()
            }
        }
    }

    func getToken() async throws -> Data {
        if let token = token { return token }

        Logger.notificationManager.debug("开始向系统请求设备令牌")
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        guard try await UNUserNotificationCenter.current().requestAuthorization(options: options) else {
            throw NotificationManagerError.authorizationDenied
        }

        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.tokenContinuation = continuation
            Task {
                try await Task.sleep(nanoseconds: 10 * 1_000_000_000)  // 10 seconds timeout
                if let continuation = self.tokenContinuation {
                    Logger.notificationManager.error("获取设备令牌超时")
                    continuation.resume(throwing: NotificationManagerError.deviceTokenTimeout)
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
            Logger.notificationManager.error("无法获取到通知令牌")
            tokenContinuation.resume(throwing: NotificationManagerError.failedToRegister(error))
            return
        }
        Logger.notificationManager.debug("获取到通知令牌: \(token.hexString)")
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
