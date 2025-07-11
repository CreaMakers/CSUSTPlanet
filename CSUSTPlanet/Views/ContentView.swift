//
//  ContentView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/7.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var globalVars: GlobalVars

    var preferredColorScheme: ColorScheme? {
        switch globalVars.appearance {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }

    var body: some View {
        TabView(selection: $globalVars.selectedTab) {
            NavigationStack {
                FeaturesView()
            }
            .tabItem {
                Label("功能", systemImage: "square.grid.2x2")
            }
            .tag(0)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("我的", systemImage: "person")
            }
            .tag(1)
        }
        .preferredColorScheme(preferredColorScheme)
    }
}

#Preview {
    ContentView()
        .environmentObject(GlobalVars())
        .environmentObject(AuthManager())
}
