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
    static let activityHelper = Logger(subsystem: appSubsystem, category: "ActivityHelper")
    static let notificationManager = Logger(subsystem: appSubsystem, category: "NotificationManager")
    static let sharedModel = Logger(subsystem: appSubsystem, category: "SharedModel")
    static let electricityBindingUtil = Logger(subsystem: appSubsystem, category: "ElectricityBindingUtil")
    static let trackHelper = Logger(subsystem: appSubsystem, category: "TrackHelper")
    static let backgroundTaskHelper = Logger(subsystem: appSubsystem, category: "BackgroundTaskHelper")

    static let gradeBackgroundTask = Logger(subsystem: appSubsystem, category: "GradeBackgroundTask")

    static let dormElectricityWidget = Logger(subsystem: widgetSubsystem, category: "DormElectricityWidget")
    static let gradeAnalysisWidget = Logger(subsystem: widgetSubsystem, category: "GradeAnalysisWidget")
}
