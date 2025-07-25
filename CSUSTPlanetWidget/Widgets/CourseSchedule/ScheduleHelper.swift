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

struct FilteredCoursesResult {
    let currentCourse: CourseDisplayInfo?
    let upcomingCourses: [CourseDisplayInfo]
}

class ScheduleHelper {
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

    static let weekCount = 20

    static func getSemesterStatus(for date: Date, semesterStartDate: Date) -> SemesterStatus {
        let calendar = Calendar.current
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

    static func getUnfinishedCourses(
        for date: Date,
        in schedule: CourseScheduleData,
        maxCount: Int,
        at currentTime: Date = .now
    ) -> [CourseDisplayInfo] {
        let allDailyCourses = getCourses(for: date, in: schedule)

        if allDailyCourses.isEmpty || maxCount <= 0 {
            return []
        }

        let calendar = Calendar.current
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

    static func getCourses(for date: Date, in schedule: CourseScheduleData) -> [CourseDisplayInfo] {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        let startDate = calendar.startOfDay(for: schedule.semesterStartDate)

        let dayDifference = calendar.dateComponents([.day], from: startDate, to: targetDate).day ?? -1

        guard dayDifference >= 0 else {
            return []
        }

        let currentWeek = (dayDifference / 7) + 1

        let weekdayComponent = calendar.component(.weekday, from: targetDate)
        guard let currentDayOfWeek = DayOfWeek(rawValue: weekdayComponent - 1) else {
            return []
        }

        guard let coursesForWeek = schedule.weeklyCourses[currentWeek] else {
            return []
        }

        let coursesForToday = coursesForWeek.filter { $0.session.dayOfWeek == currentDayOfWeek }

        return coursesForToday.sorted { $0.session.startSection < $1.session.startSection }
    }

    static func filterCurrentAndUpcomingCourses(
        from dailyCourses: [CourseDisplayInfo],
        at currentTime: Date = .now
    ) -> FilteredCoursesResult {
        var currentCourse: CourseDisplayInfo? = nil
        var upcomingCourses: [CourseDisplayInfo] = []

        let calendar = Calendar.current

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

            guard let courseStartDate = date(from: courseStartTimeString, on: currentTime, using: calendar),
                  let courseEndDate = date(from: courseEndTimeString, on: currentTime, using: calendar)
            else {
                continue
            }

            if currentTime >= courseStartDate && currentTime < courseEndDate {
                currentCourse = courseInfo
            } else if currentTime < courseStartDate {
                upcomingCourses.append(courseInfo)
            }
        }

        return FilteredCoursesResult(currentCourse: currentCourse, upcomingCourses: upcomingCourses)
    }

    static func date(from timeString: String, on date: Date, using calendar: Calendar) -> Date? {
        let components = timeString.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return nil }

        return calendar.date(
            bySettingHour: components[0],
            minute: components[1],
            second: 0,
            of: date
        )
    }

    static func getWeekday(from date: Date) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)

        let weekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return weekdays[weekday - 1]
    }

    static func calculateCurrentWeek(from start: Date, for date: Date) -> Int? {
        let startDate = Calendar.current.startOfDay(for: start)
        let todayDate = Calendar.current.startOfDay(for: date)

        let components = Calendar.current.dateComponents([.day], from: startDate, to: todayDate)
        guard let days = components.day else { return 1 }

        if days < 0 { return nil }
        let weekNumber = Int(floor(Double(days) / 7.0)) + 1

        if weekNumber < 1 || weekNumber > weekCount {
            return nil
        }

        return weekNumber
    }

    static func daysUntilSemesterStart(from semesterStartDate: Date, currentDate: Date) -> Int? {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: semesterStartDate)
        let today = calendar.startOfDay(for: currentDate)
        let components = calendar.dateComponents([.day], from: today, to: startDate)
        guard let days = components.day else { return nil }
        return days > 0 ? days : nil
    }

    static func getCourseColors(courses: [Course]) -> [String: Color] {
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
