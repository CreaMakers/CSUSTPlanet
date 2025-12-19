//
//  OverviewViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import Foundation
import SwiftData

@MainActor
class OverviewViewModel: ObservableObject {
    @Published var gradeAnalysisData: Cached<[EduHelper.CourseGrade]>?
    @Published var examScheduleData: Cached<[EduHelper.Exam]>?
    @Published var courseScheduleData: Cached<CourseScheduleData>?
    @Published var urgentCoursesData: Cached<UrgentCoursesData>?
    @Published var electricityDorms: [Dorm] = []

    func loadData() {
        let context = SharedModelUtil.mainContext

        gradeAnalysisData = MMKVHelper.shared.courseGradesCache
        examScheduleData = MMKVHelper.shared.examSchedulesCache
        courseScheduleData = MMKVHelper.shared.courseScheduleCache
        urgentCoursesData = MMKVHelper.shared.urgentCoursesCache

        let dormDescriptor = FetchDescriptor<Dorm>()
        if let dorms = try? context.fetch(dormDescriptor) {
            electricityDorms = dorms
        }
    }

    // MARK: - Computed Properties for View

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "早上好"
        case 12..<14: return "中午好"
        case 14..<19: return "下午好"
        case 19..<24: return "晚上好"
        default: return "夜深了"
        }
    }

    var weekInfo: String? {
        guard let data = courseScheduleData?.value else { return nil }

        let semester = data.semester ?? "默认学期"

        if let currentWeek = CourseScheduleUtil.getCurrentWeek(
            semesterStartDate: data.semesterStartDate,
            now: Date()
        ) {
            return "\(semester) 第\(currentWeek)周"
        }

        return semester
    }

    var todayCourses: [(course: CourseDisplayInfo, isCurrent: Bool)]? {
        guard let schedule = courseScheduleData?.value else { return nil }
        return CourseScheduleUtil.getUnfinishedCourses(
            semesterStartDate: schedule.semesterStartDate,
            now: Date(),
            courses: schedule.courses
        )
    }

    var currentGradeAnalysis: GradeAnalysisData? {
        guard let courseGrades = gradeAnalysisData?.value else { return nil }
        return GradeAnalysisData.fromCourseGrades(courseGrades)
    }

    var primaryDorm: Dorm? {
        electricityDorms.first(where: { $0.isFavorite }) ?? electricityDorms.first
    }

    var electricityExhaustionInfo: String? {
        guard let dorm = primaryDorm, let records = dorm.records, !records.isEmpty else { return nil }
        guard let predictionDate = ElectricityUtil.predictExhaustionDate(from: records) else { return nil }

        let now = Date()
        let interval = predictionDate.timeIntervalSince(now)
        guard interval > 0 else { return nil }

        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if days > 0 {
            return "预计\(days)天后电量耗尽"
        } else if hours > 0 {
            return "预计\(hours)小时后电量耗尽"
        } else {
            return "预计\(minutes)分钟后电量耗尽"
        }
    }

    var pendingExams: [EduHelper.Exam] {
        guard let examData = examScheduleData?.value else { return [] }
        return examData.filter { Date() <= $0.examEndTime }
    }

    var urgentCourses: [UrgentCoursesData.Course] {
        guard let data = urgentCoursesData?.value else { return [] }
        return data.courses
    }

    var displayedUrgentCourses: [UrgentCoursesData.Course] {
        Array(urgentCourses.prefix(2))
    }

    var urgentCoursesRemainingCount: Int {
        max(0, urgentCourses.count - 2)
    }

    var displayedExams: [EduHelper.Exam] {
        Array(pendingExams.prefix(2))
    }

    var examsRemainingCount: Int {
        max(0, pendingExams.count - 2)
    }

    func daysUntilExam(_ exam: EduHelper.Exam) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let examDay = calendar.startOfDay(for: exam.examStartTime)
        let components = calendar.dateComponents([.day], from: startOfDay, to: examDay)
        return components.day ?? 0
    }

    func formatCourseTime(_ startSection: Int, _ endSection: Int) -> String {
        let startIndex = startSection - 1
        let endIndex = endSection - 1

        guard startIndex >= 0 && startIndex < CourseScheduleUtil.sectionTimeString.count,
            endIndex >= 0 && endIndex < CourseScheduleUtil.sectionTimeString.count
        else {
            return "时间未知"
        }

        return "\(CourseScheduleUtil.sectionTimeString[startIndex].0) - \(CourseScheduleUtil.sectionTimeString[endIndex].1)"
    }
}
