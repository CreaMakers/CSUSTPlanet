//
//  CourseScheduleViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/18.
//

import CSUSTKit
import Foundation
import SwiftUI

struct CourseDisplayInfo: Identifiable {
    let id = UUID()
    let course: Course
    let session: ScheduleSession
    let color: Color
}

@MainActor
class CourseScheduleViewModel: ObservableObject {
    private var eduHelper: EduHelper

    // TabView显示的第几周
    @Published var currentWeek: Int = 1
    private var courses: [Course] = []

    @Published var weeklyCourses: [Int: [CourseDisplayInfo]] = [:]

    @Published var isCoursesLoading: Bool = false

    @Published var isShowingError: Bool = false
    @Published var errorMessage: String = ""

    @Published var availableSemesters: [String] = []
    @Published var selectedSemester: String? = nil
    @Published var isSemestersLoading: Bool = false

    // 开学日期
    @Published var semesterStartDate: Date? = nil
    // 当日日期
    // 假设2025-09-25
    let today: Date = .now

    // 当前日期在第几周
    @Published var realCurrentWeek: Int? = nil

    let colSpacing: CGFloat = 4 // 列间距
    let rowSpacing: CGFloat = 4 // 行间距
    let timeColWidth: CGFloat = 35 // 左侧时间列宽度
    let headerHeight: CGFloat = 50 // 顶部日期行的高度
    let sectionHeight: CGFloat = 70 // 单个课程格子的高度
    let weekCount: Int = 20 // 学期总周数

    let sectionTime: [(String, String)] = [
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

    var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    init(eduHelper: EduHelper) {
        self.eduHelper = eduHelper
        processCourses()
    }

    func handleSemesterChange(oldSemester: String?, newSemester: String?) {
        loadCourses()
    }

    func loadAvailableSemesters() {
        isSemestersLoading = true
        Task {
            defer {
                isSemestersLoading = false
            }

            do {
                (availableSemesters, selectedSemester) = try await eduHelper.courseService.getAvailableSemestersForCourseSchedule()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func loadCourses() {
        isCoursesLoading = true
        Task {
            defer {
                isCoursesLoading = false
            }

            do {
                courses = try await eduHelper.courseService.getCourseSchedule(academicYearSemester: selectedSemester)
                let semesterStartDate = try await eduHelper.semesterService.getSemesterStartDate(academicYearSemester: selectedSemester)
                self.semesterStartDate = semesterStartDate
                let calculatedWeek = calculateCurrentWeek(from: semesterStartDate, for: today)
                self.realCurrentWeek = calculatedWeek

                if let week = calculatedWeek {
                    withAnimation {
                        self.currentWeek = week
                    }
                }

                processCourses()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func goToCurrentWeek() {
        if let realWeek = realCurrentWeek, realWeek > 0 && realWeek <= weekCount {
            withAnimation {
                self.currentWeek = realWeek
            }
        } else {
            withAnimation {
                self.currentWeek = 1
            }
        }
    }

    func processCourses() {
        var courseColorMap: [String: Color] = [:]
        var colorIndex = 0

        for course in courses.sorted(by: { $0.courseName < $1.courseName }) {
            if courseColorMap[course.courseName] == nil {
                courseColorMap[course.courseName] = ColorHelper.courseColors[colorIndex % ColorHelper.courseColors.count]
                colorIndex += 1
            }
        }

        debugPrint(courseColorMap)

        var processedCourses: [Int: [CourseDisplayInfo]] = [:]

        for course in courses {
            for session in course.sessions {
                let displayInfo = CourseDisplayInfo(course: course, session: session, color: courseColorMap[course.courseName] ?? .gray)

                for week in session.weeks {
                    processedCourses[week, default: []].append(displayInfo)
                }
            }
        }
        weeklyCourses = processedCourses
    }

    // 计算指定日期属于第几周
    func calculateCurrentWeek(from start: Date, for date: Date) -> Int? {
        // Calendar.current.startOfDay(for:) 确保我们只比较日期，忽略时间
        let startDate = Calendar.current.startOfDay(for: start)
        let todayDate = Calendar.current.startOfDay(for: date)

        // 计算两个日期之间相差的天数
        let components = Calendar.current.dateComponents([.day], from: startDate, to: todayDate)
        guard let days = components.day else { return 1 }

        if days < 0 { return nil }

        // 天数除以7，结果加1就是周数
        let weekNumber = Int(floor(Double(days) / 7.0)) + 1

        if weekNumber < 1 || weekNumber > weekCount {
            return nil
        }

        return weekNumber
    }

    // 获取指定教学周的所有日期
    func getDatesForWeek(_ week: Int, semesterStartDate: Date) -> [Date] {
        var dates: [Date] = []
        guard let calendar = Calendar(identifier: .gregorian) as Calendar? else { return [] }

        // 计算该周的周日是哪一天
        let daysToAdd = (week - 1) * 7
        guard let firstDayOfWeek = calendar.date(byAdding: .day, value: daysToAdd, to: semesterStartDate) else { return [] }

        // 从周日开始，生成7天的日期
        for i in 0 ..< 7 {
            if let date = calendar.date(byAdding: .day, value: i, to: firstDayOfWeek) {
                dates.append(date)
            }
        }
        return dates
    }

    func dayOfWeekToString(_ day: DayOfWeek) -> String {
        switch day {
        case .monday: return "一"
        case .tuesday: return "二"
        case .wednesday: return "三"
        case .thursday: return "四"
        case .friday: return "五"
        case .saturday: return "六"
        case .sunday: return "日"
        }
    }

    // 计算课程卡片的高度
    func calculateHeight(for session: ScheduleSession) -> CGFloat {
        let sections = CGFloat(session.endSection - session.startSection + 1)
        return sections * sectionHeight + (sections - 1) * rowSpacing
    }

    // 计算课程卡片的 Y 轴偏移
    func calculateYOffset(for session: ScheduleSession) -> CGFloat {
        let y = CGFloat(session.startSection - 1)
        return y * sectionHeight + y * rowSpacing
    }

    // 计算课程卡片的 X 轴偏移
    func calculateXOffset(for day: DayOfWeek, columnWidth: CGFloat) -> CGFloat {
        let x = CGFloat(day.rawValue)
        return timeColWidth + colSpacing + (x * columnWidth) + (x * colSpacing)
    }

    func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
}
