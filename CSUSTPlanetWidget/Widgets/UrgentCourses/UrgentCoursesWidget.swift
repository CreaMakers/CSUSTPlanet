//
//  UrgentCoursesWidget.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/10/13.
//

import CSUSTKit
import Foundation
import SwiftUI
import WidgetKit

func mockUrgentCoursesEntry(configuration: UrgentCoursesIntent?) -> UrgentCoursesEntry {
    return UrgentCoursesEntry(
        date: .now,
        configuration: configuration ?? UrgentCoursesIntent(),
        data: UrgentCoursesData(courses: [
            UrgentCoursesData.Course(name: "马克思主义基本原理课外实践", id: "1"),
            UrgentCoursesData.Course(name: "程序设计、算法与数据结构（三）", id: "2"),
            UrgentCoursesData.Course(name: "大学物理B（下）", id: "3"),
            UrgentCoursesData.Course(name: "大学物理实验B", id: "4"),
            UrgentCoursesData.Course(name: "测试作业", id: "5"),
        ]),
        lastUpdated: .now.addingTimeInterval(-3600)
    )
}

struct UrgentCoursesProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> UrgentCoursesEntry {
        mockUrgentCoursesEntry(configuration: nil)
    }

    func snapshot(for configuration: UrgentCoursesIntent, in context: Context) async -> UrgentCoursesEntry {
        mockUrgentCoursesEntry(configuration: configuration)
    }

    func timeline(for configuration: UrgentCoursesIntent, in context: Context) async -> Timeline<UrgentCoursesEntry> {
        MMKVHelper.shared.setup()
        defer {
            MMKVHelper.shared.close()
        }

        var finalData: Cached<UrgentCoursesData>? = nil
        if let urgentCourses = MMKVHelper.shared.urgentCoursesCache {
            finalData = urgentCourses
        }

        let ssoHelper = SSOHelper(session: CookieHelper.shared.session)
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
                finalData = Cached<UrgentCoursesData>(cachedAt: .now, value: UrgentCoursesData.fromCourses(urgentCourses))
            }
        }

        return Timeline(
            entries: [
                UrgentCoursesEntry(
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

struct UrgentCoursesEntry: TimelineEntry {
    let date: Date
    let configuration: UrgentCoursesIntent
    let data: UrgentCoursesData?
    let lastUpdated: Date?
}

struct UrgentCoursesWidget: Widget {
    let kind: String = "UrgentCoursesWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: UrgentCoursesIntent.self, provider: UrgentCoursesProvider()) { entry in
            UrgentCoursesEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("待提交作业")
        .description("查看网络课程平台的待提交作业课程")
        .supportedFamilies([.systemSmall])
    }
}
