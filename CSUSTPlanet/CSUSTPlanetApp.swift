//
//  CSUSTPlanetApp.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/7.
//

import AppIntents
import SwiftData
import SwiftUI

@main
struct CSUSTPlanetApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager = AuthManager()

    init() {
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            KeychainHelper.deleteAll()
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }

        let asyncDependency: @Sendable () async -> ModelContainer = { @MainActor in
            return SharedModel.container
        }
        AppDependencyManager.shared.add(key: "ModelContainer", dependency: asyncDependency)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(GlobalVars.shared)
                .environmentObject(authManager)
        }
        .modelContainer(SharedModel.container)
    }
}
