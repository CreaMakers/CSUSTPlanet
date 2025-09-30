//
//  AppDelegate.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/15.
//

import Foundation
import MMKV
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationHelper.shared.handleNotificationRegistrationSuccess(token: deviceToken)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        MMKV.initialize(rootDir: nil)
        if let mmkv = MMKV.default() {
            if mmkv.contains(key: "mmkv") {
                let value = mmkv.string(forKey: "mmkv")
                debugPrint("MMKV exists", value ?? "nil")
            } else {
                mmkv.set("Hello, MMKV!", forKey: "mmkv")
                debugPrint("MMKV not exists")
            }
        }

        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
