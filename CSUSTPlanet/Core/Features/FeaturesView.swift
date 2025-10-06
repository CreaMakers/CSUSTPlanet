//
//  FeaturesView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import SwiftUI

struct FeaturesView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var globalVars: GlobalVars
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Unified Colors
    private var sectionBackgroundColor: Color {
        Color(UIColor.systemGroupedBackground)
    }

    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(UIColor.secondarySystemGroupedBackground) : Color(UIColor.systemBackground)
    }

    private var pillBackgroundColor: Color {
        colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color(UIColor.secondarySystemFill)
    }

    private var featureShadowColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.05)
    }

    private var iconBackgroundOpacity: Double { 0.15 }

    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                featureSection(
                    title: "教务系统",
                    status: {
                        HStack(spacing: 8) {
                            if authManager.isSSOLoggingIn {
                                statusPillView("正在登录统一认证...")
                            } else if !authManager.isLoggedIn {
                                actionPillView("登录后使用") {
                                    globalVars.selectedTab = .profile
                                }
                            }

                            if authManager.isEducationLoggingIn {
                                statusPillView("登录中")
                            } else if authManager.isLoggedIn && !authManager.isSSOLoggingIn {
                                actionPillView("重新登录") {
                                    authManager.loginToEducation()
                                }
                            }
                        }
                    }
                ) {
                    featureLink(destination: GradeQueryView(), title: "成绩查询", icon: "doc.text.magnifyingglass", color: .blue)
                    featureLink(destination: GradeAnalysisView(), title: "成绩分析", icon: "chart.bar", color: .green)
                    featureLink(destination: ExamScheduleView(), title: "考试安排", icon: "pencil.and.outline", color: .orange)
                    featureLink(destination: CourseScheduleView(), title: "我的课表", icon: "calendar", color: .purple)
                }

                featureSection(
                    title: "网络课程中心",
                    status: {
                        HStack(spacing: 8) {
                            if authManager.isSSOLoggingIn {
                                statusPillView("正在登录统一认证...")
                            } else if !authManager.isLoggedIn {
                                actionPillView("登录后使用") {
                                    globalVars.selectedTab = .profile
                                }
                            }

                            if authManager.isMoocLoggingIn {
                                statusPillView("登录中")
                            } else if authManager.isLoggedIn && !authManager.isSSOLoggingIn {
                                actionPillView("重新登录") {
                                    authManager.loginToMooc()
                                }
                            }
                        }
                    }
                ) {
                    featureLink(destination: CoursesView(), title: "课程列表", icon: "book", color: .indigo, disabled: authManager.moocHelper == nil)
                    featureLink(destination: UrgentCoursesView(), title: "待提交作业", icon: "doc.text", color: .red)
                }

                featureSection(title: "生活服务") {
                    featureLink(destination: ElectricityQueryView(), title: "电量查询", icon: "bolt.fill", color: .yellow)
                    featureLink(destination: CampusMapView(), title: "校园地图", icon: "map", color: .mint)
                    featureLink(destination: SchoolCalendarListView(), title: "校历", icon: "calendar", color: .pink)
                }

                featureSection(title: "考试查询") {
                    featureLink(destination: CETView(), title: "四六级", icon: "character.book.closed", color: .brown)
                    featureLink(destination: MandarinView(), title: "普通话", icon: "mic.fill", color: .teal)
                }
            }
            .padding()
        }
        .background(sectionBackgroundColor)
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

    // MARK: - Feature Section

    @ViewBuilder
    private func featureSection<Content: View, StatusContent: View>(
        title: String,
        @ViewBuilder status: () -> StatusContent = { EmptyView() },
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.title2.bold())
                Spacer()
                status()
                    .frame(height: 28)
            }
            .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 16) {
                content()
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Feature Link

    @ViewBuilder
    private func featureLink<Destination: View>(destination: Destination, title: String, icon: String, color: Color, disabled: Bool = false) -> some View {
        NavigationLink(destination: destination) {
            let cardBackground: Color = cardBackgroundColor

            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(iconBackgroundOpacity))
                    .cornerRadius(8)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .cornerRadius(12)
            .shadow(color: featureShadowColor, radius: 5, x: 0, y: 2)
        }
        .disabled(disabled)
        .opacity(disabled ? 0.6 : 1.0)
        .allowsHitTesting(!disabled)
    }

    // MARK: - Status Pill

    @ViewBuilder
    private func statusPillView(_ text: String) -> some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.75, anchor: .center)
                .frame(width: 14, height: 14)
            Text(text)
                .font(.caption2)
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(Capsule().fill(pillBackgroundColor))
    }

    // MARK: - Action Pill

    @ViewBuilder
    private func actionPillView(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(text)
                    .font(.caption2)
            }
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(Capsule().fill(pillBackgroundColor))
            .contentShape(Capsule())
        }
    }
}

// MARK: - Preview

#Preview {
    FeaturesView()
        .environmentObject(AuthManager())
        .environmentObject(GlobalVars.shared)
}
