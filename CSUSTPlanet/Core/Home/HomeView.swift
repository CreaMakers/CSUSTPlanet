//
//  HomeView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import SwiftUI

struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // 成绩分析部分
                HomeGradeAnalysisView(data: viewModel.gradeAnalysisData)

                // 今日课程部分
                HomeTodayCoursesView(
                    courseScheduleData: viewModel.courseScheduleData?.value,
                    todayCourses: viewModel.todayCourses,
                    formatCourseTime: viewModel.formatCourseTime
                )

                // 待提交作业部分
                HomeUrgentCoursesView(urgentCourseData: viewModel.urgentCourseData)

                // 电量查询部分
                HomeElectricityView(
                    electricityDorms: viewModel.electricityDorms,
                    totalElectricityDorms: viewModel.totalElectricityDorms,
                    getLastRecord: viewModel.getLastRecord
                )

                // 考试安排部分
                HomeExamScheduleView(examScheduleData: viewModel.examScheduleData)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            viewModel.loadData()
        }
    }
}

#Preview {
    HomeView()
}
