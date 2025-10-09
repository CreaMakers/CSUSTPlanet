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
    @Published var totalElectricityDorms: Int = 0
    @Published var todayCourses: [CourseDisplayInfo] = []

    // MARK: - DEBUG时间处理
    private var currentTime: Date {
        // #if DEBUG
        //     // let formatter = DateFormatter()
        //     // formatter.dateFormat = "yyyy-MM-dd HH:mm"
        //     // return formatter.date(from: "2025-09-18 17:38") ?? Date()
        // #else
        return Date()
        // #endif
    }

    func loadData() {
        let context = SharedModel.context

        gradeAnalysisData = MMKVManager.shared.courseGradesCache
        examScheduleData = MMKVManager.shared.examSchedulesCache
        courseScheduleData = MMKVManager.shared.courseScheduleCache
        urgentCourseData = MMKVManager.shared.urgentCoursesCache

        // 加载宿舍电量数据，按最新记录时间排序，最多取2个
        let dormDescriptor = FetchDescriptor<Dorm>()
        if let dorms = try? context.fetch(dormDescriptor) {
            let domsWithRecords = dorms.filter { !($0.records?.isEmpty ?? true) }  // 只保留有电量记录的宿舍
            totalElectricityDorms = domsWithRecords.count
            electricityDorms =
                domsWithRecords
                .sorted { dorm1, dorm2 in
                    let record1 = dorm1.records?.max(by: { $0.date < $1.date })
                    let record2 = dorm2.records?.max(by: { $0.date < $1.date })
                    return (record1?.date ?? Date.distantPast) > (record2?.date ?? Date.distantPast)
                }
                .prefix(2)
                .map { $0 }
        }

        // 加载今日课程数据
        if let scheduleData = courseScheduleData {
            todayCourses = getTodayCourses(from: scheduleData.value)
        }
    }

    func getLastRecord(for dorm: Dorm) -> ElectricityRecord? {
        return dorm.records?.max(by: { $0.date < $1.date })
    }

    // MARK: - 今日课程相关方法
    private func getTodayCourses(from scheduleData: CourseScheduleData) -> [CourseDisplayInfo] {
        let calendar = Calendar.current
        let today = currentTime
        let targetDate = calendar.startOfDay(for: today)
        let startDate = calendar.startOfDay(for: scheduleData.semesterStartDate)

        let dayDifference = calendar.dateComponents([.day], from: startDate, to: targetDate).day ?? -1

        guard dayDifference >= 0 else {
            return []
        }

        let currentWeek = (dayDifference / 7) + 1
        let weekdayComponent = calendar.component(.weekday, from: targetDate)

        guard let currentDayOfWeek = EduHelper.DayOfWeek(rawValue: weekdayComponent - 1) else {
            return []
        }

        let weeklyCourses = {
            var processedCourses: [Int: [CourseDisplayInfo]] = [:]
            for course in scheduleData.courses {
                for session in course.sessions {
                    let displayInfo = CourseDisplayInfo(course: course, session: session)
                    for week in session.weeks {
                        processedCourses[week, default: []].append(displayInfo)
                    }
                }
            }
            return processedCourses
        }()

        guard let coursesForWeek = weeklyCourses[currentWeek] else {
            return []
        }

        let coursesForToday = coursesForWeek.filter { $0.session.dayOfWeek == currentDayOfWeek }

        return getUnfinishedCourses(from: coursesForToday, at: today)
    }

    private func getUnfinishedCourses(from dailyCourses: [CourseDisplayInfo], at currentTime: Date) -> [CourseDisplayInfo] {
        let sectionTimes: [(String, String)] = [
            ("08:00", "08:45"),
            ("08:55", "09:40"),
            ("10:10", "10:55"),
            ("11:05", "11:50"),
            ("14:00", "14:45"),
            ("14:55", "15:40"),
            ("16:10", "16:55"),
            ("17:05", "17:50"),
            ("19:30", "20:15"),
            ("20:25", "21:10"),
        ]

        let calendar = Calendar.current
        var unfinishedCourses: [CourseDisplayInfo] = []

        for courseInfo in dailyCourses {
            let endSectionIndex = courseInfo.session.endSection - 1

            guard endSectionIndex >= 0 && endSectionIndex < sectionTimes.count else {
                continue
            }

            let courseEndTimeString = sectionTimes[endSectionIndex].1

            guard let courseEndDate = dateFromTimeString(courseEndTimeString, on: currentTime, using: calendar) else {
                continue
            }

            // 包含正在进行的课程和未开始的课程
            if currentTime < courseEndDate {
                unfinishedCourses.append(courseInfo)
            }
        }

        return unfinishedCourses.sorted { $0.session.startSection < $1.session.startSection }
    }

    private func dateFromTimeString(_ timeString: String, on date: Date, using calendar: Calendar) -> Date? {
        let components = timeString.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return nil }

        return calendar.date(
            bySettingHour: components[0],
            minute: components[1],
            second: 0,
            of: date
        )
    }

    func formatCourseTime(_ startSection: Int, _ endSection: Int) -> String {
        let sectionTimes: [(String, String)] = [
            ("08:00", "08:45"),
            ("08:55", "09:40"),
            ("10:10", "10:55"),
            ("11:05", "11:50"),
            ("14:00", "14:45"),
            ("14:55", "15:40"),
            ("16:10", "16:55"),
            ("17:05", "17:50"),
            ("19:30", "20:15"),
            ("20:25", "21:10"),
        ]

        let startIndex = startSection - 1
        let endIndex = endSection - 1

        guard startIndex >= 0 && startIndex < sectionTimes.count,
            endIndex >= 0 && endIndex < sectionTimes.count
        else {
            return "时间未知"
        }

        return "\(sectionTimes[startIndex].0) - \(sectionTimes[endIndex].1)"
    }
}
