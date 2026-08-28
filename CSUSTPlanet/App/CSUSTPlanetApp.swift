//
//  CSUSTPlanetApp.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/7.
//

import AppIntents
import OSLog
import SwiftUI

@main
struct CSUSTPlanetApp: App {
    #if os(macOS)
    private enum WindowSize {
        static let minWidth: CGFloat = 960
        static let minHeight: CGFloat = 540
        static let defaultWidth: CGFloat = 1280
        static let defaultHeight: CGFloat = 720
    }
    #endif

    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    @Environment(\.scenePhase) private var scenePhase

    init() {
        let databaseManager = DatabaseManager.shared
        if MMKVHelper.CourseSchedule.currentScheduleID == nil || databaseManager.pool != nil {
            CustomCourseScheduleHelper.syncActiveCourseSchedule()
        }
        _ = TrackHelper.shared
        _ = NotificationManager.shared
        _ = GlobalManager.shared

        #if os(iOS)
        _ = BackgroundTaskHelper.shared
        _ = ActivityManager.shared
        #endif
    }

    var body: some Scene {
        Group {
            #if os(macOS)
            Window("云岭星球", id: "main") {
                ContentView()
                    .frame(minWidth: WindowSize.minWidth, minHeight: WindowSize.minHeight)
            }
            .defaultSize(width: WindowSize.defaultWidth, height: WindowSize.defaultHeight)
            .windowResizability(.contentMinSize)
            AssignmentsCoursePageScene()
            #else
            WindowGroup {
                ContentView()
            }
            #endif
        }
        .onChange(of: scenePhase) { _, newPhase in
            LifecycleManager.shared.publishScenePhaseChange(to: newPhase)
        }
    }
}
