//
//  ContentView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/7.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var globalVars: GlobalVars

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
                NewsView()
            }
            .tabItem {
                Label("新鲜事", systemImage: "newspaper")
            }
            .tag(1)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("我的", systemImage: "person")
            }
            .tag(2)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserManager())
        .environmentObject(GlobalVars())
}
