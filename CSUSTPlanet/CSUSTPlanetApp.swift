//
//  CSUSTPlanetApp.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/7.
//

import SwiftUI

@main
struct CSUSTPlanetApp: App {
    @StateObject private var userManager = UserManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userManager)
        }
    }
}
