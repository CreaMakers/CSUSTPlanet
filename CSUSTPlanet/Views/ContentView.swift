//
//  ContentView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/7.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("功能", systemImage: "square.grid.2x2") {
                NavigationStack {
                    FeaturesView()
                }
            }
            Tab("新鲜事", systemImage: "newspaper") {
                NavigationStack {
                    NewsView()
                }
            }
            Tab("我的", systemImage: "person") {
                NavigationStack {
                    ProfileView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserManager())
}
