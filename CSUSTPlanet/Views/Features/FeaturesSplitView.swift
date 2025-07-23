//
//  FeaturesSplitView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/19.
//

import SwiftUI

struct FeaturesSplitView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var globalVars: GlobalVars

    @State var selectedFeature: FeatureSection? = nil

    enum FeatureSection: Hashable {
        case gradeQuery, gradeAnalysis, examSchedule, courseSchedule
        case moocCourses
        case electricity, map, calendar
        case cet, mandarin
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedFeature) {
                Section("教务系统") {
                    if authManager.isSSOLoggingIn {
                        HStack {
                            ProgressView().padding(.horizontal, 6)
                            Text("正在登录统一认证...")
                        }
                    } else if authManager.isEducationLoggingIn {
                        Button(action: authManager.loginToEducation) {
                            HStack {
                                ProgressView().padding(.horizontal, 6).id(authManager.eduLoginID)
                                Text("正在登录教务系统 (点击重试)")
                            }
                        }
                    } else if authManager.isLoggedIn {
                        if let _ = authManager.eduHelper {
                            NavigationLink(value: FeatureSection.gradeQuery) {
                                ColoredLabel(title: "成绩查询", iconName: "doc.text.magnifyingglass", color: .blue)
                            }
                            NavigationLink(value: FeatureSection.gradeAnalysis) {
                                ColoredLabel(title: "成绩分析", iconName: "chart.bar", color: .green)
                            }
                            NavigationLink(value: FeatureSection.examSchedule) {
                                ColoredLabel(title: "考试安排", iconName: "pencil.and.outline", color: .orange)
                            }
                            NavigationLink(value: FeatureSection.courseSchedule) {
                                ColoredLabel(title: "课表", iconName: "calendar", color: .purple)
                            }
                        } else {
                            Button(action: authManager.loginToEducation) {
                                ColoredLabel(title: "重新登录教务系统", iconName: "graduationcap", color: .orange)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        Button(action: {
                            globalVars.selectedTab = 1
                        }) {
                            ColoredLabel(title: "前往登录统一认证", iconName: "person.crop.circle.badge.plus", color: .blue)
                        }
                    }
                }
                Section("网络课程中心") {
                    if authManager.isSSOLoggingIn {
                        HStack {
                            ProgressView().padding(.horizontal, 6)
                            Text("正在登录统一认证...")
                        }
                    } else if authManager.isMoocLoggingIn {
                        Button(action: authManager.loginToMooc) {
                            HStack {
                                ProgressView().padding(.horizontal, 6).id(authManager.moocLoginID)
                                Text("正在登录网络课程中心 (点击重试)")
                            }
                        }
                    } else if authManager.isLoggedIn {
                        if let _ = authManager.moocHelper {
                            NavigationLink(value: FeatureSection.moocCourses) {
                                ColoredLabel(title: "课程列表", iconName: "book", color: .indigo)
                            }
                        } else {
                            Button(action: authManager.loginToMooc) {
                                ColoredLabel(title: "重新登录网络课程中心", iconName: "book.closed", color: .mint)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        Button(action: {
                            globalVars.selectedTab = 1
                        }) {
                            ColoredLabel(title: "前往登录统一认证", iconName: "person.crop.circle.badge.plus", color: .blue)
                        }
                    }
                }
                Section("生活服务") {
                    NavigationLink(value: FeatureSection.electricity) {
                        ColoredLabel(title: "电量查询", iconName: "bolt.fill", color: .yellow)
                    }
                    NavigationLink(value: FeatureSection.map) {
                        ColoredLabel(title: "校园地图", iconName: "map", color: .mint)
                    }
                    NavigationLink(value: FeatureSection.calendar) {
                        ColoredLabel(title: "校历", iconName: "calendar", color: .pink)
                    }
                }
                Section("考试查询") {
                    NavigationLink(value: FeatureSection.cet) {
                        ColoredLabel(title: "四六级", iconName: "character.book.closed", color: .brown)
                    }
                    NavigationLink(value: FeatureSection.mandarin) {
                        ColoredLabel(title: "普通话", iconName: "mic.fill", color: .teal)
                    }
                }
            }
        } detail: {
            NavigationStack {
                switch selectedFeature {
                case .gradeQuery:
                    if let eduHelper = authManager.eduHelper {
                        GradeQueryView(eduHelper: eduHelper)
                    }
                case .gradeAnalysis:
                    if let eduHelper = authManager.eduHelper {
                        GradeAnalysisView(eduHelper: eduHelper)
                    }
                case .examSchedule:
                    if let eduHelper = authManager.eduHelper {
                        ExamScheduleView(eduHelper: eduHelper)
                    }
                case .courseSchedule:
                    if let eduHelper = authManager.eduHelper {
                        CourseScheduleView(eduHelper: eduHelper)
                    }
                case .moocCourses:
                    if let moocHelper = authManager.moocHelper {
                        CoursesView(moocHelper: moocHelper)
                    }
                case .electricity:
                    ElectricityQueryView()
                case .map:
                    CampusMapView()
                case .calendar:
                    SchoolCalendarListView()
                case .cet:
                    CETView()
                case .mandarin:
                    MandarinView()
                case nil:
                    Text("请选择一个选项")
                }
            }
        }
        .onChange(of: globalVars.isFromElectricityWidget) {
            if globalVars.isFromElectricityWidget {
                selectedFeature = .electricity
                globalVars.isFromElectricityWidget = false
            }
        }
    }
}

#Preview {
    FeaturesSplitView()
}
