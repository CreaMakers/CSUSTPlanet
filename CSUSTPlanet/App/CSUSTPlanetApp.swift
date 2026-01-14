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
import TipKit

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
                .task {
                    
                    try? Tips.resetDatastore()//加上这一行就能每次都触发，删除后就只在第一次打开地图时显示
                    
                    try? Tips.configure([
                        .displayFrequency(.immediate),
                        .datastoreLocation(.applicationDefault)
                    ])
                }
        }
        .modelContainer(SharedModelUtil.container)
    }
}
