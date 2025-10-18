//
//  CourseScheduleHelper.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/17.
//

import CSUSTKit
import Foundation

enum SemesterStatus {
    case beforeSemester
    case inSemester
    case afterSemester
}
class CourseScheduleHelper {

    // MARK: - Properties

    /// 学期总周数，基本上不会超过20周，固定为20周即可
    static let weekCount: Int = 20

    /// 课程节次时间表
    static let sectionTimeString: [(String, String)] = [
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

    /// 月份格式化器 用于显示月份 `M`
    static var monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M"
        return formatter
    }()

    /// 日期格式化器 用于显示日 `d`
    static var dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()

    /// 日期格式化器 用于显示日期 `yyyy-MM-dd`
    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let calendar = Calendar.current

    // MARK: - Methods

    /// 计算周到课程列表的字典 用于显示整个课表
    /// - Returns: 周到课程列表的字典
    static func getWeeklyCourses(_ courses: [EduHelper.Course]) -> [Int: [CourseDisplayInfo]] {
        var weeklyCourses: [Int: [CourseDisplayInfo]] = [:]
        for course in courses {
            for session in course.sessions {
                let displayInfo = CourseDisplayInfo(course: course, session: session)
                for week in session.weeks {
                    weeklyCourses[week, default: []].append(displayInfo)
                }
            }
        }
        return weeklyCourses
    }

    /// 通过学期开始日期和当前时间来计算当前周
    /// - Parameters:
    ///   - semesterStartDate: 学期开始日期
    ///   - now: 当前时间
    /// - Returns: 当前周数，若当前日期在学期开始前或学期结束后则返回nil
    static func getCurrentWeek(semesterStartDate: Date, now: Date) -> Int? {
        let startDate = calendar.startOfDay(for: semesterStartDate)
        let todayDate = calendar.startOfDay(for: now)

        // 计算两个日期之间相差的天数
        let components = calendar.dateComponents([.day], from: startDate, to: todayDate)
        guard let days = components.day else { return 1 }

        if days < 0 { return nil }

        // 天数除以7，结果加1就是周数
        let weekNumber = Int(floor(Double(days) / 7.0)) + 1

        if weekNumber < 1 || weekNumber > weekCount {
            return nil
        }

        return weekNumber
    }

    /// 获取指定周的所有日期（周日、周一、...、周六）
    /// - Parameters:
    ///   - semesterStartDate: 学期开始日期
    ///   - week: 第几周
    /// - Returns: 该周的所有日期数组
    static func getDatesForWeek(semesterStartDate: Date, week: Int) -> [Date] {
        var dates: [Date] = []
        guard let calendar = Calendar(identifier: .gregorian) as Calendar? else { return [] }

        // 计算该周的周日是哪一天
        let daysToAdd = (week - 1) * 7
        guard let firstDayOfWeek = calendar.date(byAdding: .day, value: daysToAdd, to: semesterStartDate) else { return [] }

        // 从周日开始，生成7天的日期
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: firstDayOfWeek) {
                dates.append(date)
            }
        }
        return dates
    }

    /// 判断指定日期是否为今天
    /// - Parameter date: 指定日期
    /// - Returns: 是否为今天
    static func isToday(_ date: Date) -> Bool {
        return calendar.isDateInToday(date)
    }

    /// 获取当前学期状态（开学前、学期中、学期后）
    /// - Parameters:
    ///   - semesterStartDate: 学期开始日期
    ///   - date: 目标日期
    /// - Returns: 当前学期状态
    static func getSemesterStatus(semesterStartDate: Date, date: Date) -> SemesterStatus {
        let targetDate = calendar.startOfDay(for: date)
        let startDate = calendar.startOfDay(for: semesterStartDate)

        guard let endDate = calendar.date(byAdding: .weekOfYear, value: weekCount, to: startDate) else {
            return .afterSemester
        }

        if targetDate < startDate {
            return .beforeSemester
        } else if targetDate >= startDate && targetDate < endDate {
            return .inSemester
        } else {
            return .afterSemester
        }
    }

    /// 获取日期对应的星期
    /// - Parameter date: 目标日期
    /// - Returns: 星期
    static func getDayOfWeek(_ date: Date) -> EduHelper.DayOfWeek {
        let weekday = calendar.component(.weekday, from: date)

        switch weekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .sunday
        }
    }

    /// 计算当前距离开学还有多少天
    /// - Parameters:
    ///   - semesterStartDate: 学期开始日期
    ///   - currentDate: 当前日期
    /// - Returns: 距离开学的天数（如果开学日期在未来），否则返回nil
    static func getDaysUntilSemesterStart(semesterStartDate: Date, currentDate: Date) -> Int? {
        let startDate = calendar.startOfDay(for: semesterStartDate)
        let today = calendar.startOfDay(for: currentDate)
        let components = calendar.dateComponents([.day], from: today, to: startDate)
        guard let days = components.day else { return nil }
        return days > 0 ? days : nil
    }

    /// 获取指定日期的所有未完成课程
    /// - Parameters:
    ///   - date: 目标日期和时间，用于定位课表和判断课程状态。
    ///   - schedule: 课程表数据。
    /// - Returns: 当天所有未完成课程的列表，按开始时间排序。
    static func getUnfinishedCourses(
        semesterStartDate: Date,
        now: Date,
        courses: [EduHelper.Course]
    ) -> [CourseDisplayInfo] {
        let startOfTargetDate = calendar.startOfDay(for: now)
        let startOfSemester = calendar.startOfDay(for: semesterStartDate)

        guard let dayDifference = calendar.dateComponents([.day], from: startOfSemester, to: startOfTargetDate).day, dayDifference >= 0 else {
            return []
        }

        let currentWeek = (dayDifference / 7) + 1
        let weekdayComponent = calendar.component(.weekday, from: startOfTargetDate)
        guard let currentDayOfWeek = EduHelper.DayOfWeek(rawValue: weekdayComponent - 1) else {
            return []
        }

        let allDailyCourses = courses.flatMap { course in
            course.sessions.compactMap { session -> CourseDisplayInfo? in
                guard session.weeks.contains(currentWeek), session.dayOfWeek == currentDayOfWeek else {
                    return nil
                }
                return CourseDisplayInfo(course: course, session: session)
            }
        }.sorted { $0.session.startSection < $1.session.startSection }

        return allDailyCourses.filter { courseInfo in
            let endSectionIndex = courseInfo.session.endSection - 1
            guard endSectionIndex < sectionTimeString.count else { return false }
            let endTimeString = sectionTimeString[endSectionIndex].1
            let components = endTimeString.split(separator: ":").compactMap { Int($0) }
            guard components.count == 2,
                let courseEndDate = calendar.date(bySettingHour: components[0], minute: components[1], second: 0, of: now)
            else {
                return false
            }

            return now < courseEndDate
        }
    }
}

// MARK: - DayOfWeek Extension

extension EduHelper.DayOfWeek {
    /// 将周几枚举转换为对应的中文字符串
    var stringValue: String {
        switch self {
        case .monday: return "一"
        case .tuesday: return "二"
        case .wednesday: return "三"
        case .thursday: return "四"
        case .friday: return "五"
        case .saturday: return "六"
        case .sunday: return "日"
        }
    }
}
