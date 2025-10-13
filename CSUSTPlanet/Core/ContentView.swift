//
//  ContentView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/7.
//

import AlertToast
import SwiftUI
import Toasts

struct ContentView: View {
    @EnvironmentObject var globalVars: GlobalVars
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentToast) var presentToast

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
        NavigationStack {
            TabView(selection: $globalVars.selectedTab) {
                HomeView()
                    .tabItem { Label(TabItem.home.rawValue, systemImage: "house") }
                    .tag(TabItem.home)
                FeaturesView()
                    .tabItem { Label(TabItem.features.rawValue, systemImage: "square.grid.2x2") }
                    .tag(TabItem.features)
                ProfileView()
                    .tabItem { Label(TabItem.profile.rawValue, systemImage: "person") }
                    .tag(TabItem.profile)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(globalVars.selectedTab.rawValue)
                }
            }
            .toolbarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $globalVars.isFromElectricityWidget) {
                ElectricityQueryView()
            }
            .navigationDestination(isPresented: $globalVars.isFromCourseScheduleWidget) {
                CourseScheduleView()
            }
            .navigationDestination(isPresented: $globalVars.isFromGradeAnalysisWidget) {
                GradeAnalysisView()
            }
        }
        .onChange(of: authManager.isShowingEducationError) { _, newValue in
            guard newValue else { return }
            let toastValue = ToastValue(
                icon: Image(systemName: "exclamationmark.triangle"),
                message: "教务登录错误",
                button: ToastButton(title: "重试登录", color: .red) {
                    authManager.loginToEducation()
                }
            )
            presentToast(toastValue)
            authManager.isShowingEducationError = false
        }
        .onChange(of: authManager.isShowingMoocError) { _, newValue in
            guard newValue else { return }
            let toastValue = ToastValue(
                icon: Image(systemName: "exclamationmark.triangle"),
                message: "网络课程中心登录错误",
                button: ToastButton(title: "重试登录", color: .red) {
                    authManager.loginToMooc()
                }
            )
            presentToast(toastValue)
            authManager.isShowingMoocError = false
        }
        .preferredColorScheme(preferredColorScheme)
        .sheet(isPresented: globalVars.isUserAgreementShowing) {
            UserAgreementView().interactiveDismissDisabled(true)
        }
        .onOpenURL { url in
            guard url.scheme == "csustplanet", url.host == "widgets" else { return }
            switch url.pathComponents.dropFirst().first {
            case "electricity":
                globalVars.selectedTab = .features
                globalVars.isFromElectricityWidget = true
            case "gradeAnalysis":
                globalVars.selectedTab = .features
                globalVars.isFromGradeAnalysisWidget = true
            case "courseSchedule":
                globalVars.selectedTab = .features
                globalVars.isFromCourseScheduleWidget = true
            default:
                break
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GlobalVars.shared)
        .environmentObject(AuthManager.shared)
}
