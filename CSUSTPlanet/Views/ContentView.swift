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
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

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
            Group {
                if horizontalSizeClass == .regular {
                    FeaturesSplitView()
                } else {
                    FeaturesListView()
                }
            }
            .tabItem {
                Label("全部功能", systemImage: "square.grid.2x2")
            }
            .tag(0)

            Group {
                if horizontalSizeClass == .regular {
                    ProfileSplitView()
                } else {
                    NavigationStack {
                        ProfileListView()
                    }
                }
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
        .sheet(isPresented: Binding(
            get: { !globalVars.isUserAgreementAccepted },
            set: { globalVars.isUserAgreementAccepted = !$0 }
        )) {
            NavigationStack {
                UserAgreementView()
                    .interactiveDismissDisabled(true)
            }
        }
        .onOpenURL { url in
            guard url.scheme == "csustplanet", url.host == "widgets" else { return }
            switch url.pathComponents.dropFirst().first {
            case "electricity":
                globalVars.selectedTab = 0
                globalVars.isFromElectricityWidget = true
            default:
                break
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GlobalVars.shared)
        .environmentObject(AuthManager())
}
