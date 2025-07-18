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
                            Label("成绩查询", systemImage: "doc.text.magnifyingglass")
                        }
                        NavigationLink(destination: GradeAnalysisView(eduHelper: eduHelper)) {
                            Label("成绩分析", systemImage: "chart.bar")
                        }
                        NavigationLink(destination: ExamScheduleView(eduHelper: eduHelper)) {
                            Label("考试安排", systemImage: "pencil.and.outline")
                        }
                        NavigationLink(destination: CourseScheduleView(eduHelper: eduHelper)) {
                            Label("课表", systemImage: "calendar")
                        }
                    } else {
                        Button(action: authManager.loginToEducation) {
                            Label("重新初始化教务系统", systemImage: "arrow.clockwise")
                        }
                    }
                } else {
                    Button(action: {
                        globalVars.selectedTab = 1
                    }) {
                        Label("前往登录统一认证", systemImage: "person.crop.circle.badge.plus")
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
                            Label("课程列表", systemImage: "book")
                        }
                    } else {
                        Button(action: authManager.loginToMooc) {
                            Label("重新初始化网络课程中心", systemImage: "arrow.clockwise")
                        }
                    }
                } else {
                    Button(action: {
                        globalVars.selectedTab = 1
                    }) {
                        Label("前往登录统一认证", systemImage: "person.crop.circle.badge.plus")
                    }
                    .buttonStyle(.plain)
                }
            }

            Section(header: Text("生活服务")) {
                NavigationLink(destination: ElectricityQueryView()) {
                    Label("电量查询", systemImage: "bolt.fill")
                }
                NavigationLink(destination: CampusMapView()) {
                    Label("校园地图", systemImage: "map")
                }
                NavigationLink(destination: SchoolCalendarView()) {
                    Label("校历", systemImage: "calendar")
                }
            }

            Section(header: Text("考试查询")) {
                NavigationLink(destination: CETView()) {
                    Label("四六级", systemImage: "character.book.closed")
                }
                NavigationLink(destination: MandarinView()) {
                    Label("普通话", systemImage: "mic.fill")
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
