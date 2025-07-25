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
        debugPrint("TodayCoursesProvider: Fetching course schedule data for widget timeline")
        
        let descriptor = FetchDescriptor<CourseSchedule>()
        let modelContext = SharedModel.context
        let courseSchedule = try? modelContext.fetch(descriptor).first
        
        guard let data = courseSchedule?.data else {
            debugPrint("TodayCoursesProvider: No course data found. Refreshing in 1 hour.")
            let entry = TodayCoursesEntry(date: .now, configuration: configuration, data: nil)
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
            return Timeline(entries: [entry], policy: .after(nextUpdate))
        }
        
        let now: Date = .now
        let calendar = Calendar.current
        var entries: [TodayCoursesEntry] = []
        
        let semesterStatus = ScheduleHelper.getSemesterStatus(for: now, semesterStartDate: data.semesterStartDate)
        
        debugPrint("TodayCoursesProvider: Current date is \(now), Semester status is \(semesterStatus)")
        
        switch semesterStatus {
        case .beforeSemester, .afterSemester:
            debugPrint("TodayCoursesProvider: Semester is not active. Refreshing in 12 hours.")
            let entry = TodayCoursesEntry(date: now, configuration: configuration, data: data)
            let nextUpdate = now.addingTimeInterval(12 * 60 * 60)
            return Timeline(entries: [entry], policy: .after(nextUpdate))
            
        case .inSemester:
            debugPrint("TodayCoursesProvider: Semester is active. Generating daily timeline.")
            
            entries.append(TodayCoursesEntry(date: now, configuration: configuration, data: data))
            
            let todaysCourses = ScheduleHelper.getCourses(for: now, in: data)
            
            let refreshTimes: Set<Date> = todaysCourses.reduce(into: Set<Date>()) { resultSet, courseInfo in
                let startSectionIndex = courseInfo.session.startSection - 1
                let endSectionIndex = courseInfo.session.endSection - 1

                guard startSectionIndex >= 0, startSectionIndex < ScheduleHelper.sectionTimes.count,
                      endSectionIndex >= 0, endSectionIndex < ScheduleHelper.sectionTimes.count else { return }
                        
                let startTimeString = ScheduleHelper.sectionTimes[startSectionIndex].0
                if let courseStartTime = ScheduleHelper.date(from: startTimeString, on: now, using: calendar), courseStartTime > now {
                    resultSet.insert(courseStartTime)
                }
                        
                let endTimeString = ScheduleHelper.sectionTimes[endSectionIndex].1
                if let courseEndTime = ScheduleHelper.date(from: endTimeString, on: now, using: calendar), courseEndTime > now {
                    resultSet.insert(courseEndTime)
                }
            }
            
            for time in refreshTimes.sorted() {
                entries.append(TodayCoursesEntry(date: time, configuration: configuration, data: data))
            }
            
            let startOfToday = calendar.startOfDay(for: now)
            guard let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfToday) else {
                let lastEntryDate = entries.last?.date ?? now
                let fallbackUpdate = lastEntryDate.addingTimeInterval(6 * 3600)
                return Timeline(entries: entries, policy: .after(fallbackUpdate))
            }
            
            entries.append(TodayCoursesEntry(date: startOfNextDay, configuration: configuration, data: data))
            
            debugPrint("TodayCoursesProvider: Generated \(entries.count) entries for the timeline.")
            return Timeline(entries: entries, policy: .atEnd)
        }
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
