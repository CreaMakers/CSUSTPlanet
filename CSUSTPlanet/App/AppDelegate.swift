//
//  AppDelegate.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/15.
//

import Foundation
import MMKV
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationHelper.shared.handleNotificationRegistrationSuccess(token: deviceToken)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        MMKVManager.shared.setup()
        RealmManager.shared.setup()

        #if DEBUG
            Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle")?.load()

            print("App Group Folder Structure:")
            printDirectoryTree(at: Constants.sharedContainerURL!, prefix: "")
        #endif

        return true
    }

    #if DEBUG
        private func printDirectoryTree(at url: URL, prefix: String) {
            let fileManager = FileManager.default
            do {
                let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                for (index, itemURL) in contents.enumerated() {
                    let isLast = (index == contents.count - 1)
                    let connector = isLast ? "└── " : "├── "
                    let newPrefix = prefix + (isLast ? "    " : "│   ")
                    print("\(prefix)\(connector)\(itemURL.lastPathComponent)")
                    var isDirectory: ObjCBool = false
                    if fileManager.fileExists(atPath: itemURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
                        printDirectoryTree(at: itemURL, prefix: newPrefix)
                    }
                }
            } catch {
                print("\(prefix)└── 无法读取目录: \(error.localizedDescription)")
            }
        }
    #endif
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
