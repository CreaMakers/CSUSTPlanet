//
//  Logger+Extension.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2025/12/16.
//

import Foundation
import OSLog

extension Logger {
    private static var subsystem = Constants.appBundleID

    static let appDelegate = Logger(subsystem: subsystem, category: "AppDelegate")
    static let authManager = Logger(subsystem: subsystem, category: "AuthManager")
    static let activityManager = Logger(subsystem: subsystem, category: "ActivityManager")
    static let notificationHelper = Logger(subsystem: subsystem, category: "NotificationHelper")
    static let sharedModel = Logger(subsystem: subsystem, category: "SharedModel")
}
