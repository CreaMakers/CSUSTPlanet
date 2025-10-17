//
//  CourseScheduleHelper.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/17.
//

import CSUSTKit
import Foundation

class CourseScheduleHelper {

    // MARK: - Properties

    /// 学期总周数，基本上不会超过20周，固定为20周即可
    static let weekCount: Int = 20

    /// 课程节次时间表
    static let sectionTime: [(String, String)] = [
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
    static func calculateWeeklyCourses(_ courses: [EduHelper.Course]) -> [Int: [CourseDisplayInfo]] {
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
    static func calculateCurrentWeek(semesterStartDate: Date, now: Date) -> Int? {
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
