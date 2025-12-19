//
//  CSUSTPlanetApp.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/7.
//

import AppIntents
import SwiftData
import SwiftUI
import Toasts

@main
struct CSUSTPlanetApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .installToast(position: .top)
                .environmentObject(GlobalManager.shared)
                .environmentObject(AuthManager.shared)
                .environmentObject(NotificationManager.shared)
        }
        .modelContainer(SharedModelUtil.container)
    }
}
