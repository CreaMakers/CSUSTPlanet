//
//  WeeklyCoursesProvider.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/25.
//

import WidgetKit

struct WeeklyCoursesProvider: TimelineProvider {
    #if DEBUG
    // 当需要指定时间测试课表时，打断点并修改shouldMock和mockDate可以配置新的日期值
    static var shouldMock: Bool = false
    static var mockDate: String = "2025-10-20 11:49"
    #endif

    private static let refreshTimes: [(hour: Int, minute: Int)] = [
        (8, 0), (9, 41),
        (10, 0), (11, 51),
        (14, 0), (15, 41),
        (16, 0), (17, 51),
        (19, 30), (21, 11),
    ]

    func placeholder(in context: Context) -> WeeklyCoursesEntry {
        return .mockEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (WeeklyCoursesEntry) -> Void) {
        if context.isPreview {
            completion(.mockEntry())
        } else if let schedule = MMKVHelper.CourseSchedule.activeCourseSchedule?.value,
            let data = schedule.data
        {
            completion(WeeklyCoursesEntry(date: .now, data: data, scheduleName: schedule.scheduleName))
        } else {
            completion(.mockEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeeklyCoursesEntry>) -> Void) {
        let currentDate = resolveCurrentDate()
        let calendar = Calendar.current

        // 无缓存数据时：1小时后重试
        guard let schedule = MMKVHelper.CourseSchedule.activeCourseSchedule?.value,
            let data = schedule.data
        else {
            let entry = WeeklyCoursesEntry(date: currentDate, data: nil, scheduleName: nil)
            let nextUpdate = calendar.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate.addingTimeInterval(3600)
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
            return
        }

        // 放假或未开学时：12小时刷新一次
        let semesterStatus = CourseScheduleUtil.getSemesterStatus(semesterStartDate: data.semesterStartDate, date: currentDate, weekCount: data.weekCount)
        guard semesterStatus == .inSemester else {
            let entry = WeeklyCoursesEntry(date: currentDate, data: data, scheduleName: schedule.scheduleName)
            let refreshDate = calendar.date(byAdding: .hour, value: 12, to: currentDate) ?? currentDate.addingTimeInterval(12 * 3600)
            completion(Timeline(entries: [entry], policy: .after(refreshDate)))
            return
        }

        // 正常学期中：构建当天的多条时间线
        var entries: [WeeklyCoursesEntry] = [
            WeeklyCoursesEntry(date: currentDate, data: data, scheduleName: schedule.scheduleName)
        ]

        let startOfDay = calendar.startOfDay(for: currentDate)

        for time in Self.refreshTimes {
            if let entryDate = calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: startOfDay),
                entryDate > currentDate
            {
                let entry = WeeklyCoursesEntry(date: entryDate, data: data, scheduleName: schedule.scheduleName)
                entries.append(entry)
            }
        }

        // 第二天凌晨重新获取时间线
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? currentDate.addingTimeInterval(24 * 3600)

        completion(Timeline(entries: entries, policy: .after(tomorrowStart)))
        return
    }

    private func resolveCurrentDate() -> Date {
        #if DEBUG
        if Self.shouldMock {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            return dateFormatter.date(from: Self.mockDate) ?? .now
        }
        #endif
        return .now
    }
}
