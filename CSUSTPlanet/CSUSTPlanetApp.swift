//
//  CSUSTPlanetApp.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/7.
//

import SwiftData
import SwiftUI

@main
struct CSUSTPlanetApp: App {
    @StateObject private var globalVars = GlobalVars()
    @StateObject private var authManager = AuthManager()

    var container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Dorm.self, ElectricityRecord.self)
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(globalVars)
                .environmentObject(authManager)
        }
        .modelContainer(container)
    }
}
