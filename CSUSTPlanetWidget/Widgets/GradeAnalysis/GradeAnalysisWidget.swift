//
//  GradeAnalysisWidget.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/7/22.
//

import Charts
import CSUSTKit
import Foundation
import SwiftData
import SwiftUI
import WidgetKit

func mockEntry(configuration: GradeAnalysisIntent?) -> GradeAnalysisEntry {
    return GradeAnalysisEntry(
        date: .now,
        configuration: configuration ?? GradeAnalysisIntent(),
        data: GradeAnalysisData(
            totalCourses: 23,
            totalHours: 740,
            totalCredits: 45.5,
            overallAverageGrade: 85.35,
            overallGPA: 3.26,
            gradePointDistribution: [
                GradePointEntry(gradePoint: 4.0, count: 8),
                GradePointEntry(gradePoint: 3.7, count: 7),
                GradePointEntry(gradePoint: 3.3, count: 2),
                GradePointEntry(gradePoint: 3.0, count: 2),
                GradePointEntry(gradePoint: 2.7, count: 3),
                GradePointEntry(gradePoint: 2.0, count: 1),
                GradePointEntry(gradePoint: 1.7, count: 1),
                GradePointEntry(gradePoint: 1.3, count: 1),
                GradePointEntry(gradePoint: 1.0, count: 1),
                GradePointEntry(gradePoint: 0.0, count: 1),
            ],
            semesterAverageGrades: [
                SemesterAverageGrade(semester: "2024-2025-1", average: 88.4),
                SemesterAverageGrade(semester: "2024-2025-2", average: 82.6),
            ],
            semesterGPAs: [
                SemesterGPA(semester: "2024-2025-1", gpa: 3.44),
                SemesterGPA(semester: "2024-2025-2", gpa: 3.09),
            ],
            lastUpdated: .now.addingTimeInterval(-3600)
        ),
    )
}

// MARK: - Provider

struct GradeAnalysisProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> GradeAnalysisEntry {
        mockEntry(configuration: nil)
    }

    func snapshot(for configuration: GradeAnalysisIntent, in context: Context) async -> GradeAnalysisEntry {
        mockEntry(configuration: configuration)
    }

    func timeline(for configuration: GradeAnalysisIntent, in context: Context) async -> Timeline<GradeAnalysisEntry> {
        debugPrint("GradeAnalysisProvider: Fetching grade analysis for widget")
        let descriptor = FetchDescriptor<GradeAnalysis>()
        let context = SharedModel.context

        var finalData: GradeAnalysisData?

        // 先从缓存中获取成绩分析
        do {
            let gradeAnalysis = try context.fetch(descriptor).first

            if let gradeAnalysis = gradeAnalysis {
                debugPrint("GradeAnalysisProvider: Successfully fetched grade analysis from database")
                finalData = gradeAnalysis.data
            }
        } catch {
            debugPrint("GradeAnalysisProvider: Error fetching grade analysis: \(error) from database")
        }

        // 再尝试联网获取数据
        debugPrint("GradeAnalysisProvider: Starting SSO login process")
        let ssoHelper = SSOHelper(cookieStorage: KeychainCookieStorage())

        // 先尝试使用保存的cookie登录统一认证
        let hasValidSession: Bool
        if (try? await ssoHelper.getLoginUser()) == nil {
            debugPrint("GradeAnalysisProvider: No valid cookie found, attempting login with username and password")
            // 保存的cookie无效，尝试账号密码登录
            if let username = KeychainHelper.retrieve(key: "SSOUsername"),
               let password = KeychainHelper.retrieve(key: "SSOPassword")
            {
                hasValidSession = (try? await ssoHelper.login(username: username, password: password)) != nil
            } else {
                hasValidSession = false
            }
        } else {
            debugPrint("GradeAnalysisProvider: Valid cookie found, no need to login with username and password")
            hasValidSession = true
        }

        if hasValidSession, let eduHelper = try? EduHelper(session: await ssoHelper.loginToEducation()) {
            debugPrint("GradeAnalysisProvider: EduHelper initialized successfully")
            // 教务系统登录成功
            if let courseGrades = try? await eduHelper.courseService.getCourseGrades(), !courseGrades.isEmpty {
                debugPrint("GradeAnalysisProvider: Successfully fetched course grades from EduHelper")
                // 成绩获取成功
                finalData = GradeAnalysisData.fromCourseGrades(courseGrades)
                debugPrint("GradeAnalysisProvider: Successfully created final grade analysis")
            }
        }

        return Timeline(entries: [GradeAnalysisEntry(date: .now, configuration: configuration, data: finalData)], policy: .never)
    }
}

struct GradeAnalysisEntry: TimelineEntry {
    let date: Date
    let configuration: GradeAnalysisIntent
    let data: GradeAnalysisData?
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
