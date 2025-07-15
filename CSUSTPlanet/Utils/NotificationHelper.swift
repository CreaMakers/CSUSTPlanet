//
//  NotificationHelper.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/15.
//

import Foundation
import UIKit
import UserNotifications

class NotificationHelper {
    static let shared = NotificationHelper()

    private init() {}

    private var onDeviceToken: ((String) -> Void)?

    func requestAuthorization(onDeviceToken: @escaping (String) -> Void, onResult: @escaping (Bool) -> Void, onError: @escaping (Error) -> Void) {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            if let error = error {
                onError(error)
            } else if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    self.onDeviceToken = onDeviceToken
                }
            }
            onResult(granted)
        }
    }

    func handleNotificationRegistrationSuccess(token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        onDeviceToken?(tokenString)
    }
}
