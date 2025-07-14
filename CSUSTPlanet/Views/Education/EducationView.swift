//
//  EducationView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/14.
//

import SwiftUI

struct EducationView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        if authManager.isSSOLoggingIn {
            VStack {
                ProgressView("正在登录统一认证...")
                Text("请稍候")
                    .foregroundColor(.secondary)
            }
        } else if authManager.isEducationLoggingIn {
            VStack {
                ProgressView("正在登录教务...")
                Text("请稍候")
                    .foregroundColor(.secondary)
            }
        } else if authManager.isLoggedIn {
            Form {
                Section(header: Text("成绩")) {
                    NavigationLink(destination: GradeQueryView(authManager: authManager)) {
                        Label("成绩查询", systemImage: "doc.text.magnifyingglass")
                    }
                    NavigationLink(destination: GradeAnalysisView(authManager: authManager)) {
                        Label("成绩分析", systemImage: "chart.bar")
                    }
                    NavigationLink(destination: ExamScheduleView(authManager: authManager)) {
                        Label("考试安排", systemImage: "pencil.and.outline")
                    }
                }

                Section(header: Text("课程")) {
                    NavigationLink(destination: CourseScheduleView()) {
                        Label("课表", systemImage: "calendar")
                    }
                }
            }
            .navigationTitle("教务系统")
        } else {
            NotLoginView()
        }
    }
}

#Preview {
    EducationView()
}
