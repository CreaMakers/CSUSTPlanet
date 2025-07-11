//
//  FeaturesView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import SwiftUI

struct FeaturesView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        if authManager.isLoggedIn {
            ScrollView {
                VStack(spacing: 20) {
                    GroupBox(label: Text("成绩相关").font(.headline)) {
                        HStack(spacing: 15) {
                            FunctionItem(icon: "doc.text.magnifyingglass", title: "成绩查询", destination: GradeQueryView(authManager: authManager))
                            FunctionItem(icon: "chart.bar", title: "成绩分析", destination: GradeAnalysisView())
                            FunctionItem(icon: "pencil.and.outline", title: "考试安排", destination: ExamScheduleView(authManager: authManager))
                        }
                    }

                    GroupBox(label: Text("课程相关").font(.headline)) {
                        HStack(spacing: 15) {
                            FunctionItem(icon: "calendar", title: "课表", destination: CourseScheduleView())
                            FunctionItem(icon: "calendar.badge.clock", title: "校历", destination: SchoolCalendarView())
                        }
                    }

                    GroupBox(label: Text("生活服务").font(.headline)) {
                        HStack(spacing: 15) {
                            FunctionItem(icon: "bolt.fill", title: "电费查询", destination: ElectricityQueryView())
                            FunctionItem(icon: "map", title: "校园地图", destination: CampusMapView())
                        }
                    }

                    GroupBox(label: Text("语言考试").font(.headline)) {
                        HStack(spacing: 15) {
                            FunctionItem(icon: "character.book.closed", title: "四六级", destination: CETView())
                            FunctionItem(icon: "mic.fill", title: "普通话", destination: MandarinView())
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("功能")
        } else if authManager.isLoggingIn {
            VStack {
                ProgressView("正在登录...")
                    .padding()
                Text("请稍候")
                    .foregroundColor(.secondary)
            }
        } else {
            NotLoginView()
        }
    }

    struct FunctionItem<Destination: View>: View {
        let icon: String
        let title: String
        let destination: Destination

        var body: some View {
            NavigationLink(destination: destination) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.accent.opacity(0.1))
                            .frame(width: 60, height: 60)

                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundColor(.accent)
                    }

                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(width: 70)
            }
        }
    }
}

#Preview {
    NavigationStack {
        FeaturesView()
    }
    .environmentObject(AuthManager())
}
