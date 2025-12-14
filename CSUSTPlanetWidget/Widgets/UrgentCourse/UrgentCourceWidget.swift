//
//  UrgentCourceWidget.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/10/13.
//

import CSUSTKit
import Foundation
import SwiftUI
import WidgetKit

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

        var finalData: Cached<UrgentCourseData>? = nil
        if let urgentCourses = MMKVManager.shared.urgentCoursesCache {
            finalData = urgentCourses
        }

        let ssoHelper = SSOHelper(cookieStorage: KeychainCookieStorage())
        let hasValidSession: Bool
        if (try? await ssoHelper.getLoginUser()) == nil {
            if let username = KeychainHelper.shared.ssoUsername, let password = KeychainHelper.shared.ssoPassword {
                hasValidSession = (try? await ssoHelper.login(username: username, password: password)) != nil
            } else {
                hasValidSession = false
            }
        } else {
            hasValidSession = true
        }

        if hasValidSession, let moocHelper = try? MoocHelper(session: await ssoHelper.loginToMooc()) {
            if let urgentCourses = try? await moocHelper.getCourseNamesWithPendingHomeworks() {
                finalData = Cached<UrgentCourseData>(cachedAt: .now, value: UrgentCourseData.fromCourses(urgentCourses))
            }
        }

        return Timeline(
            entries: [
                UrgentCourseEntry(
                    date: .now,
                    configuration: configuration,
                    data: finalData?.value,
                    lastUpdated: finalData?.cachedAt
                )
            ],
            policy: .never
        )
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
