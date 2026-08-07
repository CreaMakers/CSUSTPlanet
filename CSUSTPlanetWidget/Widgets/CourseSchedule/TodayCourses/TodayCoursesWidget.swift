//
//  TodayCoursesWidget.swift
//  CSUSTPlanetWidgetExtension
//8
//  Created by Zhe_Learn on 2025/7/23.
//

import SwiftUI
import WidgetKit

struct TodayCoursesWidget: Widget {
    let kind: String = "TodayCoursesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayCoursesProvider()) { entry in
            TodayCoursesEntryView(entry: entry)
        }
        .configurationDisplayName(CourseScheduleUtil.courseScheduleTitle)
        .description("显示我的课表安排")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#Preview("Small - 空", as: .systemSmall, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.init(date: .now, data: nil, scheduleName: nil)
}

#Preview("Medium - 空", as: .systemMedium, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.init(date: .now, data: nil, scheduleName: nil)
}

#Preview("Large - 空", as: .systemLarge, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.init(date: .now, data: nil, scheduleName: nil)
}

#Preview("Small - 学期未开始（一周以外）", as: .systemSmall, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry(semester: "2025-2026-1", semesterStartDate: "2025-09-07", date: "2025-08-30 04:00")
}

#Preview("Medium - 学期未开始（一周以外）", as: .systemMedium, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry(semester: "2025-2026-1", semesterStartDate: "2025-09-07", date: "2025-08-30 04:00")
}

#Preview("Large - 学期未开始（一周以外）", as: .systemLarge, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry(semester: "2025-2026-1", semesterStartDate: "2025-09-07", date: "2025-08-30 04:00")
}

#Preview("Small - 学期未开始（一周以内）", as: .systemSmall, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry(semester: "2025-2026-1", semesterStartDate: "2025-09-07", date: "2025-09-04 04:00")
}

#Preview("Medium - 学期未开始（一周以内）", as: .systemMedium, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry(semester: "2025-2026-1", semesterStartDate: "2025-09-07", date: "2025-09-04 04:00")
}

#Preview("Large - 学期未开始（一周以内）", as: .systemLarge, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry(semester: "2025-2026-1", semesterStartDate: "2025-09-07", date: "2025-09-04 04:00")
}

#Preview("Small - 学期已结束", as: .systemSmall, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry(semester: "2025-2026-1", semesterStartDate: "2025-09-07", date: "2026-09-15 04:00")
}

#Preview("Medium - 学期已结束", as: .systemMedium, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry(semester: "2025-2026-1", semesterStartDate: "2025-09-07", date: "2026-09-15 04:00")
}

#Preview("Large - 学期已结束", as: .systemLarge, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry(semester: "2025-2026-1", semesterStartDate: "2025-09-07", date: "2026-09-15 04:00")
}

#Preview("Small - 完整", as: .systemSmall, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry()
}

#Preview("Medium - 完整", as: .systemMedium, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry()
}

#Preview("Large - 完整", as: .systemLarge, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry()
}

#Preview("Small - 一节课", as: .systemSmall, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry(semester: "2025-2026-1", semesterStartDate: "2025-09-07", date: "2025-09-17 20:00")
}

#Preview("Medium - 一节课", as: .systemMedium, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry(semester: "2025-2026-1", semesterStartDate: "2025-09-07", date: "2025-09-17 20:00")
}

#Preview("Large - 一节课", as: .systemLarge, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry(semester: "2025-2026-1", semesterStartDate: "2025-09-07", date: "2025-09-17 20:00")
}

#Preview("Small - 课已上完（明天没课）", as: .systemSmall, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry(semester: "2025-2026-1", semesterStartDate: "2025-09-07", date: "2025-09-17 22:00")
}

#Preview("Medium - 课已上完（明天没课）", as: .systemMedium, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry(semester: "2025-2026-1", semesterStartDate: "2025-09-07", date: "2025-09-17 22:00")
}

#Preview("Large - 课已上完（明天没课）", as: .systemLarge, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry(semester: "2025-2026-1", semesterStartDate: "2025-09-07", date: "2025-09-17 22:00")
}

#Preview("Small - 明日课程预报", as: .systemSmall, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockTomorrowPreviewEntry()
}

#Preview("Medium - 明日课程预报", as: .systemMedium, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockTomorrowPreviewEntry()
}

#Preview("Large - 明日课程预报", as: .systemLarge, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockTomorrowPreviewEntry()
}

#Preview("Small - 无课程（明天也没课）", as: .systemSmall, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry(semester: "2025-2026-1", semesterStartDate: "2025-09-07", date: "2025-09-18 10:00")
}

#Preview("Medium - 无课程（明天也没课）", as: .systemMedium, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry(semester: "2025-2026-1", semesterStartDate: "2025-09-07", date: "2025-09-18 10:00")
}

#Preview("Large - 无课程（明天也没课）", as: .systemLarge, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry(semester: "2025-2026-1", semesterStartDate: "2025-09-07", date: "2025-09-18 10:00")
}
