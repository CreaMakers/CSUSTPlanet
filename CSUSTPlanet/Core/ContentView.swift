//
//  ContentView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/7.
//

import Inject
import SwiftUI
import Toasts

struct ContentView: View {
    @ObserveInjection var inject

    @EnvironmentObject var GlobalManager: GlobalManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentToast) var presentToast

    var preferredColorScheme: ColorScheme? {
        switch GlobalManager.appearance {
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
            TabView(selection: $GlobalManager.selectedTab) {
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
            .navigationTitle(GlobalManager.selectedTab.rawValue)
            .toolbarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $GlobalManager.isFromElectricityWidget) {
                ElectricityQueryView()
            }
            .navigationDestination(isPresented: $GlobalManager.isFromCourseScheduleWidget) {
                CourseScheduleView()
            }
            .navigationDestination(isPresented: $GlobalManager.isFromGradeAnalysisWidget) {
                GradeAnalysisView()
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
        .sheet(isPresented: GlobalManager.isUserAgreementShowing) {
            UserAgreementView().interactiveDismissDisabled(true)
        }

        // MARK: - URL处理

        .onOpenURL { url in
            guard url.scheme == "csustplanet", url.host == "widgets" else { return }
            switch url.pathComponents.dropFirst().first {
            case "electricity": GlobalManager.isFromElectricityWidget = true
            case "gradeAnalysis": GlobalManager.isFromGradeAnalysisWidget = true
            case "courseSchedule": GlobalManager.isFromCourseScheduleWidget = true
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
