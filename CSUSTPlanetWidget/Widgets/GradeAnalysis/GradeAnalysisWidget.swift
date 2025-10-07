//
//  GradeAnalysisWidget.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/7/22.
//

import CSUSTKit
import Charts
import Foundation
import SwiftData
import SwiftUI
import WidgetKit

func mockGradeAnalysisEntry(configuration: GradeAnalysisIntent?) -> GradeAnalysisEntry {
    return GradeAnalysisEntry(
        date: .now,
        configuration: configuration ?? GradeAnalysisIntent(),
        data: GradeAnalysisEntry.GradeAnalysisData(
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
        MMKVManager.shared.setupMMKV()
        debugPrint("GradeAnalysisProvider: Fetching grade analysis for widget")

        var finalData: Cached<[EduHelper.CourseGrade]>? = nil

        // 先从缓存中获取成绩分析
        if let gradeAnalysis = MMKVManager.shared.courseGradesCache {
            debugPrint("GradeAnalysisProvider: Successfully fetched grade analysis from database")
            finalData = gradeAnalysis
        }

        // 再尝试联网获取数据
        debugPrint("GradeAnalysisProvider: Starting SSO login process")
        let ssoHelper = SSOHelper(cookieStorage: KeychainCookieStorage())

        // 先尝试使用保存的cookie登录统一认证
        let hasValidSession: Bool
        if (try? await ssoHelper.getLoginUser()) == nil {
            debugPrint("GradeAnalysisProvider: No valid cookie found, attempting login with username and password")
            // 保存的cookie无效，尝试账号密码登录
            if let username = KeychainHelper.retrieve(key: "SSOUsername"), let password = KeychainHelper.retrieve(key: "SSOPassword") {
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
                finalData = Cached<[EduHelper.CourseGrade]>(cachedAt: .now, value: courseGrades)
                debugPrint("GradeAnalysisProvider: Successfully created final grade analysis")
            }
        }

        return Timeline(
            entries: [
                GradeAnalysisEntry(
                    date: .now,
                    configuration: configuration,
                    data: GradeAnalysisEntry.GradeAnalysisData.toGradeAnalysisData(finalData?.value),
                    lastUpdated: finalData?.cachedAt
                )
            ],
            policy: .never
        )
    }
}

struct GradeAnalysisEntry: TimelineEntry {
    struct GradeAnalysisData {
        var totalCourses: Int
        var totalHours: Int
        var totalCredits: Double
        var overallAverageGrade: Double
        var overallGPA: Double
        var weightedAverageGrade: Double
        var gradePointDistribution: [(gradePoint: Double, count: Int)]
        var semesterAverageGrades: [(semester: String, average: Double)]
        var semesterGPAs: [(semester: String, gpa: Double)]

        static func toGradeAnalysisData(_ courseGrades: [EduHelper.CourseGrade]?) -> GradeAnalysisData? {
            guard let courseGrades else { return nil }
            let totalCourses = courseGrades.count
            let totalHours = courseGrades.reduce(0) { $0 + $1.totalHours }
            let totalCredits = courseGrades.reduce(0) { $0 + $1.credit }
            let overallAverageGrade = totalCourses > 0 ? Double(courseGrades.reduce(0) { $0 + $1.grade }) / Double(totalCourses) : 0.0
            let overallGPA = totalCredits > 0 ? courseGrades.reduce(0) { $0 + $1.gradePoint * $1.credit } / totalCredits : 0.0
            let weightedAverageGrade = totalCredits > 0 ? courseGrades.reduce(0) { $0 + (Double($1.grade) * $1.credit) } / totalCredits : 0.0
            let gradePointDistribution = courseGrades.reduce(into: [Double: Int]()) { result, course in
                result[course.gradePoint, default: 0] += 1
            }.map { (gradePoint: $0.key, count: $0.value) }
            let semesterAverageGrades = Dictionary(grouping: courseGrades, by: { $0.semester }).map { semester, grades in
                (semester: semester, average: Double(grades.reduce(0) { $0 + $1.grade }) / Double(grades.count))
            }
            let semesterGPAs = Dictionary(grouping: courseGrades, by: { $0.semester }).map { semester, grades in
                let totalCredits = grades.reduce(0) { $0 + $1.credit }
                let totalGradePoints = grades.reduce(0) { $0 + $1.gradePoint * $1.credit }
                let gpa = totalCredits > 0 ? totalGradePoints / totalCredits : 0.0
                return (semester: semester, gpa: gpa)
            }
            return GradeAnalysisData(
                totalCourses: totalCourses,
                totalHours: totalHours,
                totalCredits: totalCredits,
                overallAverageGrade: overallAverageGrade,
                overallGPA: overallGPA,
                weightedAverageGrade: weightedAverageGrade,
                gradePointDistribution: gradePointDistribution.sorted { $0.gradePoint > $1.gradePoint },
                semesterAverageGrades: semesterAverageGrades.sorted { $0.semester < $1.semester },
                semesterGPAs: semesterGPAs.sorted { $0.semester < $1.semester }
            )
        }
    }

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
