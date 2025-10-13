//
//  UrgentCourceWidget.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/10/13.
//

import WidgetKit
import SwiftUI
import Foundation

func mockUrgentCourseEntry(configuration: UrgentCourseIntent?) -> UrgentCourseEntry {
    return UrgentCourseEntry(
        date: .now,
        configuration: configuration ?? UrgentCourseIntent(),
        data: UrgentCourseData(courses: [
            UrgentCourseData.Course(name: "马克思主义基本原理课外实践", id: "1"),
            UrgentCourseData.Course(name: "程序设计、算法与数据结构（三）", id: "2"),
            UrgentCourseData.Course(name: "大学物理B（下）", id: "3"),
            UrgentCourseData.Course(name: "大学物理实验B", id: "4"),
            UrgentCourseData.Course(name: "测试作业", id: "5"),
        ]),
        lastUpdated: .now.addingTimeInterval(-3600)
    )
}

struct UrgentCourseProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> UrgentCourseEntry {
        mockUrgentCourseEntry(configuration: nil)
    }
    
    func snapshot(for configuration: UrgentCourseIntent, in context: Context) async -> UrgentCourseEntry {
        mockUrgentCourseEntry(configuration: configuration)
    }
    
    func timeline(for configuration: UrgentCourseIntent, in context: Context) async -> Timeline<UrgentCourseEntry> {
        MMKVManager.shared.setup()
        defer {
            MMKVManager.shared.close()
        }
        
        return Timeline(entries: [], policy: .never)
    }
}

struct UrgentCourseEntry: TimelineEntry {
    let date: Date
    let configuration: UrgentCourseIntent
    let data: UrgentCourseData?
    let lastUpdated: Date?
}

struct UrgentCourceWidget: Widget {
    let kind: String = "UrgentCourseWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: UrgentCourseIntent.self, provider: UrgentCourseProvider()) { entry in
            UrgentCourseEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("待提交作业")
        .description("查看网络课程平台的待提交作业课程")
        .supportedFamilies([.systemSmall])
    }
}
