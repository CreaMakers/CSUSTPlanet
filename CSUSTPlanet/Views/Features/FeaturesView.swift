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

    var body: some View {
        Form {
            Section(header: Text("教务系统")) {
                if authManager.isSSOLoggingIn {
                    HStack {
                        ProgressView().padding(.trailing, 8)
                        Text("正在登录统一认证...")
                    }
                } else if authManager.isEducationLoggingIn {
                    HStack {
                        ProgressView().padding(.trailing, 8)
                        Text("正在登录教务系统...")
                    }
                } else if authManager.isLoggedIn {
                    if let eduHelper = authManager.eduHelper {
                        NavigationLink(destination: GradeQueryView(eduHelper: eduHelper)) {
                            ColoredLabel(title: "成绩查询", iconName: "doc.text.magnifyingglass", color: .blue)
                        }
                        NavigationLink(destination: GradeAnalysisView(eduHelper: eduHelper)) {
                            ColoredLabel(title: "成绩分析", iconName: "chart.bar", color: .green)
                        }
                        NavigationLink(destination: ExamScheduleView(eduHelper: eduHelper)) {
                            ColoredLabel(title: "考试安排", iconName: "pencil.and.outline", color: .orange)
                        }
                        NavigationLink(destination: CourseScheduleView(eduHelper: eduHelper)) {
                            ColoredLabel(title: "课表", iconName: "calendar", color: .purple)
                        }
                    } else {
                        Button(action: authManager.loginToEducation) {
                            ColoredLabel(title: "重新初始化教务系统", iconName: "arrow.clockwise", color: .gray)
                        }
                    }
                } else {
                    Button(action: {
                        globalVars.selectedTab = 1
                    }) {
                        ColoredLabel(title: "前往登录统一认证", iconName: "person.crop.circle.badge.plus", color: .red)
                    }
                    .buttonStyle(.plain)
                }
            }

            Section(header: Text("网络课程中心")) {
                if authManager.isSSOLoggingIn {
                    HStack {
                        ProgressView().padding(.trailing, 8)
                        Text("正在登录统一认证...")
                    }
                } else if authManager.isMoocLoggingIn {
                    HStack {
                        ProgressView().padding(.trailing, 8)
                        Text("正在登录网络课程中心...")
                    }
                } else if authManager.isLoggedIn {
                    if let moocHelper = authManager.moocHelper {
                        NavigationLink(destination: CoursesView(moocHelper: moocHelper)) {
                            ColoredLabel(title: "课程列表", iconName: "book", color: .indigo)
                        }
                    } else {
                        Button(action: authManager.loginToMooc) {
                            ColoredLabel(title: "重新初始化网络课程中心", iconName: "arrow.clockwise", color: .gray)
                        }
                    }
                } else {
                    Button(action: {
                        globalVars.selectedTab = 1
                    }) {
                        ColoredLabel(title: "前往登录统一认证", iconName: "person.crop.circle.badge.plus", color: .red)
                    }
                    .buttonStyle(.plain)
                }
            }

            Section(header: Text("生活服务")) {
                NavigationLink(destination: ElectricityQueryView()) {
                    ColoredLabel(title: "电量查询", iconName: "bolt.fill", color: .yellow)
                }
                NavigationLink(destination: CampusMapView()) {
                    ColoredLabel(title: "校园地图", iconName: "map", color: .mint)
                }
                NavigationLink(destination: SchoolCalendarView()) {
                    ColoredLabel(title: "校历", iconName: "calendar", color: .pink)
                }
            }

            Section(header: Text("考试查询")) {
                NavigationLink(destination: CETView()) {
                    ColoredLabel(title: "四六级", iconName: "character.book.closed", color: .brown)
                }
                NavigationLink(destination: MandarinView()) {
                    ColoredLabel(title: "普通话", iconName: "mic.fill", color: .teal)
                }
            }
        }
        .navigationTitle("全部功能")
    }
}

#Preview {
    NavigationStack {
        FeaturesView()
    }
}
