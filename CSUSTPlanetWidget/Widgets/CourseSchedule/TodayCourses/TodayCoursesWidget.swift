//
//  TodayCoursesWidget.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/7/23.
//

import SwiftData
import SwiftUI
import WidgetKit

struct TodayCoursesProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TodayCoursesEntry {
        mockTodayCoursesEntry()
    }

    func snapshot(for configuration: TodayCoursesIntent, in context: Context) async -> TodayCoursesEntry {
        mockTodayCoursesEntry()
    }

    func timeline(for configuration: TodayCoursesIntent, in context: Context) async -> Timeline<TodayCoursesEntry> {
        MMKVHelper.shared.setup()
        defer {
            MMKVHelper.shared.close()
        }

        // #if DEBUG
        //     let currentDate = {
        //         let dateFormatter = DateFormatter()
        //         dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        //         return dateFormatter.date(from: "2025-10-20 11:49")!
        //     }()
        // #else
        let currentDate: Date = .now
        // #endif

        guard let data = MMKVHelper.shared.courseScheduleCache else {
            let entry = TodayCoursesEntry(date: .now, configuration: configuration, data: nil)
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
            return Timeline(entries: [entry], policy: .after(nextUpdate))
        }

        let semesterStatus = CourseScheduleUtil.getSemesterStatus(semesterStartDate: data.value.semesterStartDate, date: currentDate)

        if semesterStatus == .beforeSemester || semesterStatus == .afterSemester {
            let entry = TodayCoursesEntry(date: currentDate, configuration: configuration, data: data.value)
            let refreshDate = Calendar.current.date(byAdding: .hour, value: 12, to: currentDate)!
            return Timeline(entries: [entry], policy: .after(refreshDate))
        }

        var entries: [TodayCoursesEntry] = []
        let calendar = Calendar.current

        entries.append(TodayCoursesEntry(date: currentDate, configuration: configuration, data: data.value))

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
                    let entry = TodayCoursesEntry(date: entryDate, configuration: configuration, data: data.value)
                    entries.append(entry)
                }
            }
        }

        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return Timeline(entries: entries, policy: .after(tomorrowStart))
    }
}

struct TodayCoursesEntry: TimelineEntry {
    let date: Date
    let configuration: TodayCoursesIntent
    let data: CourseScheduleData?
}

struct TodayCoursesWidget: Widget {
    let kind: String = "TodayCoursesWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: TodayCoursesIntent.self, provider: TodayCoursesProvider()) { entry in
            TodayCoursesEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("今日课程")
        .description("显示今天的课程安排")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
