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

    init() {
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            KeychainHelper.deleteAll()
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .installToast(position: .top)
                .environmentObject(GlobalVars.shared)
                .environmentObject(AuthManager.shared)
        }
        .modelContainer(SharedModel.container)
    }
}
