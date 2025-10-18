//
//  HomeViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import Foundation
import SwiftData

@MainActor
class HomeViewModel: ObservableObject {
    @Published var gradeAnalysisData: Cached<[EduHelper.CourseGrade]>?
    @Published var examScheduleData: Cached<[EduHelper.Exam]>?
    @Published var courseScheduleData: Cached<CourseScheduleData>?
    @Published var urgentCourseData: Cached<UrgentCourseData>?
    @Published var electricityDorms: [Dorm] = []

    func loadData() {
        let context = SharedModel.mainContext

        gradeAnalysisData = MMKVManager.shared.courseGradesCache
        examScheduleData = MMKVManager.shared.examSchedulesCache
        courseScheduleData = MMKVManager.shared.courseScheduleCache
        urgentCourseData = MMKVManager.shared.urgentCoursesCache

        let dormDescriptor = FetchDescriptor<Dorm>()
        if let dorms = try? context.fetch(dormDescriptor) {
            electricityDorms = dorms
        }
    }
}
