//
//  ScheduleHelper.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/7/23.
//

import CSUSTKit
import Foundation
import SwiftUI

enum SemesterStatus {
    case beforeSemester
    case inSemester
    case afterSemester
}

class ScheduleHelper {
    /// 每节课的开始和结束时间
    static let sectionTimes: [(String, String)] = [
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

    /// 学期总周数
    static let weekCount = 20

    /// 当前日历
    private static let calendar = Calendar.current

    /// 获取学期状态（开学前、学期中、学期后）
    /// - Parameters:
    ///   - date: 目标日期
    ///   - semesterStartDate: 学期开始日期
    /// - Returns: 学期状态
    static func getSemesterStatus(for date: Date, semesterStartDate: Date) -> SemesterStatus {
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

    /// 获取未完成的课程（当前进行的和即将开始的课程）
    /// - Parameters:
    ///   - date: 目标日期
    ///   - schedule: 课程表数据
    ///   - maxCount: 最大返回课程数
    ///   - currentTime: 目标时间
    /// - Returns: 未完成的课程列表
    static func getUnfinishedCourses(
        for date: Date,
        in schedule: CourseScheduleData,
        maxCount: Int,
        at currentTime: Date = .now
    ) -> [CourseDisplayInfo] {
        let weeklyCourses = {
            var processedCourses: [Int: [CourseDisplayInfo]] = [:]
            for course in schedule.courses {
                for session in course.sessions {
                    let displayInfo = CourseDisplayInfo(course: course, session: session)
                    for week in session.weeks {
                        processedCourses[week, default: []].append(displayInfo)
                    }
                }
            }
            return processedCourses
        }()
        let allDailyCourses = getCourses(for: date, semesterStartDate: schedule.semesterStartDate, in: weeklyCourses)

        if allDailyCourses.isEmpty || maxCount <= 0 {
            return []
        }

        if !calendar.isDate(date, inSameDayAs: currentTime) {
            if date > currentTime {
                return Array(allDailyCourses.prefix(maxCount))
            } else {
                return []
            }
        }

        let filteredResult = filterCurrentAndUpcomingCourses(from: allDailyCourses, at: currentTime)

        var unfinishedCourses: [CourseDisplayInfo] = []
        if let current = filteredResult.currentCourse {
            unfinishedCourses.append(current)
        }
        unfinishedCourses.append(contentsOf: filteredResult.upcomingCourses)

        return Array(unfinishedCourses.prefix(maxCount))
    }

    /// 获取指定日期的课程
    /// - Parameters:
    ///   - date: 目标日期
    ///   - semesterStartDate: 学期开始日期
    ///   - weeklyCourses: 按周组织的课程字典
    /// - Returns: 指定日期的课程列表
    private static func getCourses(for date: Date, semesterStartDate: Date, in weeklyCourses: [Int: [CourseDisplayInfo]]) -> [CourseDisplayInfo] {
        let targetDate = calendar.startOfDay(for: date)
        let startDate = calendar.startOfDay(for: semesterStartDate)

        let dayDifference = calendar.dateComponents([.day], from: startDate, to: targetDate).day ?? -1

        guard dayDifference >= 0 else {
            return []
        }

        let currentWeek = (dayDifference / 7) + 1

        let weekdayComponent = calendar.component(.weekday, from: targetDate)
        guard let currentDayOfWeek = EduHelper.DayOfWeek(rawValue: weekdayComponent - 1) else {
            return []
        }

        guard let coursesForWeek = weeklyCourses[currentWeek] else {
            return []
        }

        let coursesForToday = coursesForWeek.filter { $0.session.dayOfWeek == currentDayOfWeek }

        return coursesForToday.sorted { $0.session.startSection < $1.session.startSection }
    }

    /// 筛选当前的和即将到来的课程
    /// - Parameters:
    ///   - dailyCourses: 课程列表
    ///   - currentTime: 目标时间
    /// - Returns: 筛选结果（当前课程和即将到来的课程）
    private static func filterCurrentAndUpcomingCourses(
        from dailyCourses: [CourseDisplayInfo],
        at currentTime: Date = .now
    ) -> (currentCourse: CourseDisplayInfo?, upcomingCourses: [CourseDisplayInfo]) {
        var currentCourse: CourseDisplayInfo? = nil
        var upcomingCourses: [CourseDisplayInfo] = []

        for courseInfo in dailyCourses {
            let startSectionIndex = courseInfo.session.startSection - 1
            let endSectionIndex = courseInfo.session.endSection - 1

            guard startSectionIndex >= 0 && startSectionIndex < sectionTimes.count,
                endSectionIndex >= 0 && endSectionIndex < sectionTimes.count
            else {
                continue
            }

            let courseStartTimeString = sectionTimes[startSectionIndex].0
            let courseEndTimeString = sectionTimes[endSectionIndex].1

            guard let courseStartDate = date(from: courseStartTimeString, on: currentTime),
                let courseEndDate = date(from: courseEndTimeString, on: currentTime)
            else {
                continue
            }

            if currentTime >= courseStartDate && currentTime < courseEndDate {
                currentCourse = courseInfo
            } else if currentTime < courseStartDate {
                upcomingCourses.append(courseInfo)
            }
        }

        return (currentCourse: currentCourse, upcomingCourses: upcomingCourses)
    }

    /// 将时间字符串转换为日期
    /// - Parameters:
    ///   - timeString: "HH:mm"格式的时间字符串
    ///   - date: 目标日期
    /// - Returns: 转换后的日期，如果转换失败则返回nil
    private static func date(from timeString: String, on date: Date) -> Date? {
        let components = timeString.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return nil }

        return calendar.date(
            bySettingHour: components[0],
            minute: components[1],
            second: 0,
            of: date
        )
    }

    /// 获取日期对应的星期字符串
    /// - Parameter date: 目标日期
    /// - Returns: 星期字符串（如"周一"）
    static func getWeekday(from date: Date) -> String {
        let weekday = calendar.component(.weekday, from: date)

        let weekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return weekdays[weekday - 1]
    }

    /// 计算当前是第几周
    /// - Parameters:
    ///   - start: 学期开始日期
    ///   - date: 目标日期
    /// - Returns: 当前周数（如果日期在学期范围内），否则返回nil
    static func calculateCurrentWeek(from start: Date, for date: Date) -> Int? {
        let startDate = calendar.startOfDay(for: start)
        let todayDate = calendar.startOfDay(for: date)

        let components = calendar.dateComponents([.day], from: startDate, to: todayDate)
        guard let days = components.day else { return 1 }

        if days < 0 { return nil }
        let weekNumber = Int(floor(Double(days) / 7.0)) + 1

        if weekNumber < 1 || weekNumber > weekCount {
            return nil
        }

        return weekNumber
    }

    /// 计算距离开学还有多少天
    /// - Parameters:
    ///   - semesterStartDate: 学期开始日期
    ///   - currentDate: 当前日期
    /// - Returns: 距离开学的天数（如果开学日期在未来），否则返回nil
    static func daysUntilSemesterStart(from semesterStartDate: Date, currentDate: Date) -> Int? {
        let startDate = calendar.startOfDay(for: semesterStartDate)
        let today = calendar.startOfDay(for: currentDate)
        let components = calendar.dateComponents([.day], from: today, to: startDate)
        guard let days = components.day else { return nil }
        return days > 0 ? days : nil
    }

    /// 为课程分配颜色
    /// - Parameter courses: 课程列表
    /// - Returns: 课程名称到颜色的映射字典
    static func getCourseColors(courses: [EduHelper.Course]) -> [String: Color] {
        var courseColors: [String: Color] = [:]
        var colorIndex = 0
        for course in courses.sorted(by: { $0.courseName < $1.courseName }) {
            if courseColors[course.courseName] == nil {
                courseColors[course.courseName] = ColorHelper.courseColors[colorIndex % ColorHelper.courseColors.count]
                colorIndex += 1
            }
        }
        return courseColors
    }
}
