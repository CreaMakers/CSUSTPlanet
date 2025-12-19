//
//  Logger+Extension.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2025/12/16.
//

import Foundation
import OSLog

extension Logger {
    private static var appSubsystem = Constants.appBundleID
    private static var widgetSubsystem = Constants.widgetBundleID

    static let appDelegate = Logger(subsystem: appSubsystem, category: "AppDelegate")
    static let authManager = Logger(subsystem: appSubsystem, category: "AuthManager")
    static let activityManager = Logger(subsystem: appSubsystem, category: "ActivityManager")
    static let notificationManager = Logger(subsystem: appSubsystem, category: "NotificationManager")
    static let sharedModel = Logger(subsystem: appSubsystem, category: "SharedModel")
    static let electricityBindingHelper = Logger(subsystem: appSubsystem, category: "ElectricityBindingHelper")

    static let dormElectricityWidget = Logger(subsystem: widgetSubsystem, category: "DormElectricityWidget")
    static let gradeAnalysisWidget = Logger(subsystem: widgetSubsystem, category: "GradeAnalysisWidget")
}
