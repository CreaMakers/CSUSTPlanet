//
//  GradeAnalysisWidget.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/7/22.
//

import CSUSTKit
import Charts
import Foundation
import OSLog
import SwiftData
import SwiftUI
import WidgetKit

func mockGradeAnalysisEntry(configuration: GradeAnalysisIntent?) -> GradeAnalysisEntry {
    return GradeAnalysisEntry(
        date: .now,
        configuration: configuration ?? GradeAnalysisIntent(),
        data: GradeAnalysisData(
            totalCourses: 23,
            totalHours: 740,
            totalCredits: 45.5,
            overallAverageGrade: 85.35,
            overallGPA: 3.26,
            weightedAverageGrade: 83.58,
            gradePointDistribution: [
                (gradePoint: 4.0, count: 8),
                (gradePoint: 3.7, count: 7),
                (gradePoint: 3.3, count: 2),
                (gradePoint: 3.0, count: 2),
                (gradePoint: 2.7, count: 3),
                (gradePoint: 2.0, count: 1),
                (gradePoint: 1.7, count: 1),
                (gradePoint: 1.3, count: 1),
                (gradePoint: 1.0, count: 1),
                (gradePoint: 0.0, count: 1),
            ],
            semesterAverageGrades: [
                (semester: "2024-2025-1", average: 88.4),
                (semester: "2024-2025-2", average: 82.6),
            ],
            semesterGPAs: [
                (semester: "2024-2025-1", gpa: 3.44),
                (semester: "2024-2025-2", gpa: 3.09),
            ],
        ),
        lastUpdated: .now.addingTimeInterval(-3600)
    )
}

// MARK: - Provider

struct GradeAnalysisProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> GradeAnalysisEntry {
        mockGradeAnalysisEntry(configuration: nil)
    }

    func snapshot(for configuration: GradeAnalysisIntent, in context: Context) async -> GradeAnalysisEntry {
        mockGradeAnalysisEntry(configuration: configuration)
    }

    func timeline(for configuration: GradeAnalysisIntent, in context: Context) async -> Timeline<GradeAnalysisEntry> {
        MMKVHelper.shared.setup()
        defer {
            MMKVHelper.shared.close()
        }
        Logger.gradeAnalysisWidget.info("GradeAnalysisProvider: 开始获取成绩分析数据")

        var finalData: Cached<[EduHelper.CourseGrade]>? = nil

        // 先从缓存中获取成绩分析
        if let gradeAnalysis = MMKVHelper.shared.courseGradesCache {
            Logger.gradeAnalysisWidget.info("GradeAnalysisProvider: 成功从缓存获取成绩分析数据")
            finalData = gradeAnalysis
        }

        // 再尝试联网获取数据
        Logger.gradeAnalysisWidget.info("GradeAnalysisProvider: 开始SSO登录流程")
        let ssoHelper = SSOHelper(session: CookieHelper.shared.session)

        // 先尝试使用保存的cookie登录统一认证
        let hasValidSession: Bool
        if (try? await ssoHelper.getLoginUser()) == nil {
            Logger.gradeAnalysisWidget.info("GradeAnalysisProvider: 未找到有效Cookie，尝试使用账号密码登录")
            // 保存的cookie无效，尝试账号密码登录
            if let username = KeychainHelper.shared.ssoUsername, let password = KeychainHelper.shared.ssoPassword {
                hasValidSession = (try? await ssoHelper.login(username: username, password: password)) != nil
            } else {
                hasValidSession = false
            }
        } else {
            Logger.gradeAnalysisWidget.info("GradeAnalysisProvider: 找到有效Cookie，无需使用账号密码登录")
            hasValidSession = true
        }

        if hasValidSession, let eduHelper = try? EduHelper(session: await ssoHelper.loginToEducation()) {
            Logger.gradeAnalysisWidget.info("GradeAnalysisProvider: EduHelper初始化成功")
            // 教务系统登录成功
            if let courseGrades = try? await eduHelper.courseService.getCourseGrades(), !courseGrades.isEmpty {
                Logger.gradeAnalysisWidget.info("GradeAnalysisProvider: 成功从EduHelper获取成绩")
                // 成绩获取成功
                finalData = Cached<[EduHelper.CourseGrade]>(cachedAt: .now, value: courseGrades)
                Logger.gradeAnalysisWidget.info("GradeAnalysisProvider: 成功创建最终成绩分析数据")
            }
        }

        return Timeline(
            entries: [
                GradeAnalysisEntry(
                    date: .now,
                    configuration: configuration,
                    data: finalData?.value != nil ? GradeAnalysisData.fromCourseGrades(finalData!.value) : nil,
                    lastUpdated: finalData?.cachedAt
                )
            ],
            policy: .never
        )
    }
}

struct GradeAnalysisEntry: TimelineEntry {
    let date: Date
    let configuration: GradeAnalysisIntent
    let data: GradeAnalysisData?
    let lastUpdated: Date?
}

// MARK: - Widget Configuration

struct GradeAnalysisWidget: Widget {
    let kind: String = "GradeAnalysisWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: GradeAnalysisIntent.self, provider: GradeAnalysisProvider()) { entry in
            GradeAnalysisEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("成绩分析")
        .description("查看你的成绩分析和统计信息")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
