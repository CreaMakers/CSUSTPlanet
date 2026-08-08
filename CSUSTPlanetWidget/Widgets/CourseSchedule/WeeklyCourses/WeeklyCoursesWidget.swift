//
//  WeeklyCoursesWidget.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/7/25.
//

import Foundation
import SwiftUI
import WidgetKit

struct WeeklyCoursesWidget: Widget {
    let kind: String = "WeeklyCoursesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeeklyCoursesProvider()) { entry in
            WeeklyCoursesEntryView(entry: entry)
        }
        .configurationDisplayName("本周课程")
        .description("查看本周的课程安排")
        .supportedFamilies([.systemLarge])
    }
}

#Preview("空", as: .systemLarge, widget: { WeeklyCoursesWidget() }) {
    WeeklyCoursesEntry(date: .now, data: nil, scheduleName: nil)
}

#Preview("学期未开始（一周以外）", as: .systemLarge, widget: { WeeklyCoursesWidget() }) {
    WeeklyCoursesEntry.mockEntry(semester: "2025-2026-1", semesterStartDate: "2025-09-07", date: "2025-08-30 04:00")
}

#Preview("学期未开始（一周以内）", as: .systemLarge, widget: { WeeklyCoursesWidget() }) {
    WeeklyCoursesEntry.mockEntry(semester: "2025-2026-1", semesterStartDate: "2025-09-07", date: "2025-09-04 04:00")
}

#Preview("学期已结束", as: .systemLarge, widget: { WeeklyCoursesWidget() }) {
    WeeklyCoursesEntry.mockEntry(semester: "2025-2026-1", semesterStartDate: "2025-09-07", date: "2026-09-15 04:00")
}

#Preview("完整", as: .systemLarge, widget: { WeeklyCoursesWidget() }) {
    WeeklyCoursesEntry.mockEntry(semester: "2025-2026-1", semesterStartDate: "2025-09-07", date: "2025-09-21 12:40")
}
