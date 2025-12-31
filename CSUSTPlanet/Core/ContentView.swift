//
//  ContentView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/7.
//

import InjectHotReload
import SwiftUI
import Toasts

struct ContentView: View {
    @ObserveInjection var inject

    @EnvironmentObject var globalManager: GlobalManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentToast) var presentToast

    var preferredColorScheme: ColorScheme? {
        switch globalManager.appearance {
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
            TabView(selection: $globalManager.selectedTab) {
                OverviewView()
                    .tabItem {
                        Image(uiImage: UIImage(systemName: "rectangle.stack")!)
                        Text(TabItem.overview.rawValue)
                    }
                    .tag(TabItem.overview)
                FeaturesView()
                    .tabItem {
                        Image(uiImage: UIImage(systemName: "square.grid.2x2")!)
                        Text(TabItem.features.rawValue)
                    }
                    .tag(TabItem.features)
                ProfileView()
                    .tabItem {
                        Image(uiImage: UIImage(systemName: "person")!)
                        Text(TabItem.profile.rawValue)
                    }
                    .tag(TabItem.profile)
            }
            .trackRoot("App")
            .navigationTitle(globalManager.selectedTab.rawValue)
            .toolbarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $globalManager.isFromElectricityWidget) {
                ElectricityQueryView()
                    .trackRoot("Widget")
            }
            .navigationDestination(isPresented: $globalManager.isFromCourseScheduleWidget) {
                CourseScheduleView()
                    .trackRoot("Widget")
            }
            .navigationDestination(isPresented: $globalManager.isFromGradeAnalysisWidget) {
                GradeAnalysisView()
                    .trackRoot("Widget")
            }
            .navigationDestination(isPresented: $globalManager.isFromUrgentCoursesWidget) {
                UrgentCoursesView()
                    .trackRoot("Widget")
            }
        }

        // MARK: 全局Toast状态

        .onChange(of: authManager.isShowingSSOInfo) { _, newValue in
            guard newValue else { return }
            presentToast(ToastValue(icon: Image(systemName: "info.circle.fill").foregroundStyle(.blue), message: authManager.ssoInfo))
            authManager.isShowingSSOInfo = false
        }
        .onChange(of: authManager.isShowingSSOError) { _, newValue in
            guard newValue else { return }
            presentToast(ToastValue(icon: Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red), message: "统一身份认证登录错误"))
            authManager.isShowingSSOError = false
        }
        .onChange(of: authManager.isShowingEducationInfo) { _, newValue in
            guard newValue else { return }
            presentToast(ToastValue(icon: Image(systemName: "info.circle.fill").foregroundStyle(.blue), message: authManager.educationInfo))
            authManager.isShowingEducationInfo = false
        }
        .onChange(of: authManager.isShowingEducationError) { _, newValue in
            guard newValue else { return }
            presentToast(ToastValue(icon: Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red), message: "教务登录错误"))
            authManager.isShowingEducationError = false
        }
        .onChange(of: authManager.isShowingMoocInfo) { _, newValue in
            guard newValue else { return }
            presentToast(ToastValue(icon: Image(systemName: "info.circle.fill").foregroundStyle(.blue), message: authManager.moocInfo))
            authManager.isShowingMoocInfo = false
        }
        .onChange(of: authManager.isShowingMoocError) { _, newValue in
            guard newValue else { return }
            presentToast(ToastValue(icon: Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red), message: "网络课程中心登录错误"))
            authManager.isShowingMoocError = false
        }

        .preferredColorScheme(preferredColorScheme)
        .sheet(isPresented: globalManager.isUserAgreementShowing) {
            UserAgreementView().interactiveDismissDisabled(true)
        }

        // MARK: - URL处理

        .onOpenURL { url in
            guard url.scheme == "csustplanet", url.host == "widgets" else { return }
            switch url.pathComponents.dropFirst().first {
            case "electricity": globalManager.isFromElectricityWidget = true
            case "gradeAnalysis": globalManager.isFromGradeAnalysisWidget = true
            case "courseSchedule": globalManager.isFromCourseScheduleWidget = true
            case "urgentCourses": globalManager.isFromUrgentCoursesWidget = true
            default: break
            }
        }
        .enableInjection()
    }
}

#Preview {
    ContentView()
        .environmentObject(GlobalManager.shared)
        .environmentObject(AuthManager.shared)
}
