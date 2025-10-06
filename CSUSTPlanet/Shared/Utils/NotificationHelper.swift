//
//  NotificationHelper.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/15.
//

import Foundation
import UIKit
import UserNotifications

enum NotificationHelperError: Error {
    case deviceTokenTimeout
}

class NotificationHelper {
    static let shared = NotificationHelper()

    private init() {}

    private var tokenContinuations: [UUID: CheckedContinuation<String, Error>] = [:]

    func getDeviceToken() async throws -> String {
        let taskId = UUID()

        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.tokenContinuations[taskId] = continuation

            Task {
                try await Task.sleep(nanoseconds: 10 * 1_000_000_000) // 10 seconds timeout
                if let continuation = self.tokenContinuations.removeValue(forKey: taskId) {
                    continuation.resume(throwing: NotificationHelperError.deviceTokenTimeout)
                }
            }
        }
    }

    func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        return try await UNUserNotificationCenter.current().requestAuthorization(options: options)
    }

    func handleNotificationRegistrationSuccess(token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        for continuation in tokenContinuations.values {
            continuation.resume(returning: tokenString)
        }
        tokenContinuations.removeAll()
    }
}
