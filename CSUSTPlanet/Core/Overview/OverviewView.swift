//
//  OverviewView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import SwiftUI

struct OverviewView: View {
    @StateObject var viewModel = OverviewViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // 成绩分析部分
                OverviewGradeAnalysisView(data: viewModel.gradeAnalysisData)

                // 今日课程部分
                OverviewTodayCoursesView(courseScheduleData: viewModel.courseScheduleData)

                // 待提交作业部分
                OverviewUrgentCoursesView(urgentCourseData: viewModel.urgentCourseData)

                // 电量查询部分
                OverviewElectricityView(electricityDorms: viewModel.electricityDorms)

                // 考试安排部分
                OverviewExamScheduleView(examScheduleData: viewModel.examScheduleData)
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
    OverviewView()
}
