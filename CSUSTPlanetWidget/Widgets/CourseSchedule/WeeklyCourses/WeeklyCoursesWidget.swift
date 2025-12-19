//
//  WeeklyCoursesWidget.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/7/25.
//

import Foundation
import SwiftData
import SwiftUI
import WidgetKit

struct WeeklyCoursesProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WeeklyCoursesEntry {
        mockWeeklyCoursesEntry()
    }

    func snapshot(for configuration: WeeklyCoursesIntent, in context: Context) async -> WeeklyCoursesEntry {
        mockWeeklyCoursesEntry()
    }

    func timeline(for configuration: WeeklyCoursesIntent, in context: Context) async -> Timeline<WeeklyCoursesEntry> {
        MMKVHelper.shared.setup()
        defer {
            MMKVHelper.shared.close()
        }
        let currentDate: Date = .now

        guard let data = MMKVHelper.shared.courseScheduleCache else {
            let entry = WeeklyCoursesEntry(date: .now, configuration: configuration, data: nil)
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
            return Timeline(entries: [entry], policy: .after(nextUpdate))
        }

        let semesterStatus = CourseScheduleUtil.getSemesterStatus(semesterStartDate: data.value.semesterStartDate, date: currentDate)

        if semesterStatus == .beforeSemester || semesterStatus == .afterSemester {
            let entry = WeeklyCoursesEntry(date: currentDate, configuration: configuration, data: data.value)
            let refreshDate = Calendar.current.date(byAdding: .hour, value: 12, to: currentDate)!
            return Timeline(entries: [entry], policy: .after(refreshDate))
        }

        var entries: [WeeklyCoursesEntry] = []
        let calendar = Calendar.current

        entries.append(WeeklyCoursesEntry(date: currentDate, configuration: configuration, data: data.value))

        let startOfDay = calendar.startOfDay(for: currentDate)
        let refreshTimes: [(hour: Int, minute: Int)] = [
            (9, 41),
            (11, 51),
            (15, 41),
            (17, 51),
            (21, 11),
        ]

        for time in refreshTimes {
            if let entryDate = calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: startOfDay) {
                if entryDate > currentDate {
                    let entry = WeeklyCoursesEntry(date: entryDate, configuration: configuration, data: data.value)
                    entries.append(entry)
                }
            }
        }

        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return Timeline(entries: entries, policy: .after(tomorrowStart))
    }
}

struct WeeklyCoursesEntry: TimelineEntry {
    let date: Date
    let configuration: WeeklyCoursesIntent
    let data: CourseScheduleData?
}

struct WeeklyCoursesWidget: Widget {
    let kind: String = "WeeklyCoursesWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: WeeklyCoursesIntent.self, provider: WeeklyCoursesProvider()) { entry in
            WeeklyCoursesEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("本周课程")
        .description("查看本周的课程安排")
        .supportedFamilies([.systemLarge])
    }
}
