//
//  ContentView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/7.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var globalVars: GlobalVars
    @EnvironmentObject var authManager: AuthManager

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
        .alert("教务登录错误", isPresented: $authManager.isShowingEducationError) {
            Button("确定", role: .cancel) {}
            Button("重试", action: authManager.loginToEducation)
        } message: {
            Text(authManager.educationErrorMessage)
        }
        .alert("网络课程中心登录错误", isPresented: $authManager.isShowingMoocError) {
            Button("确定", role: .cancel) {}
            Button("重试", action: authManager.loginToMooc)
        } message: {
            Text(authManager.moocErrorMessage)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GlobalVars())
        .environmentObject(AuthManager())
}
