//
//  AppDelegate.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/15.
//

import Foundation
import MMKV
import OSLog
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        setupInjectionIII()
        setupStorage()
        setupNotificationCenter()
        setupUI()

        ActivityManager.shared.setup()
        NotificationHelper.shared.setup()

        return true
    }

    // MARK: - Setup Methods

    func setupStorage() {
        MMKVManager.shared.setup()
        if !MMKVManager.shared.hasLaunchedBefore {
            KeychainHelper.shared.deleteAll()
            MMKVManager.shared.hasLaunchedBefore = true
        }
    }

    func setupInjectionIII() {
        #if DEBUG
            Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle")?.load()
        #endif
    }

    func setupUI() {
        let tabBarAppearance = {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithTransparentBackground()
            tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            return tabBarAppearance
        }()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }

    func setupNotificationCenter() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Remote Notification

extension AppDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationHelper.shared.handleNotificationRegistration(token: deviceToken, error: nil)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        NotificationHelper.shared.handleNotificationRegistration(token: nil, error: error)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

// MARK: - App Lifecycle

extension AppDelegate {
    @objc
    private func appDidEnterBackground() {
        Logger.appDelegate.debug("App进入后台: appDidEnterBackground")
        ActivityManager.shared.autoUpdateActivity()
    }

    @objc
    private func appWillEnterForeground() {
        Logger.appDelegate.debug("App回到前台: appWillEnterForeground")
        ActivityManager.shared.autoUpdateActivity()
    }
}
