//
//  GradeAnalysisWidget.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/7/22.
//

import Charts
import Foundation
import SwiftData
import SwiftUI
import WidgetKit

func mockEntry(configuration: GradeAnalysisIntent?) -> GradeAnalysisEntry {
    return GradeAnalysisEntry(
        date: .now,
        configuration: configuration ?? GradeAnalysisIntent(),
        gradeAnalysis: GradeAnalysisEntry.GradeAnalysis(
            totalCourses: 23,
            totalHours: 740,
            totalCredits: 45.5,
            overallAverageGrade: 85.35,
            overallGPA: 3.26,
            gradePointDistribution: [
                GradeAnalysisEntry.GradeAnalysis.GradePointEntry(gradePoint: 4.0, count: 8),
                GradeAnalysisEntry.GradeAnalysis.GradePointEntry(gradePoint: 3.7, count: 7),
                GradeAnalysisEntry.GradeAnalysis.GradePointEntry(gradePoint: 3.3, count: 2),
                GradeAnalysisEntry.GradeAnalysis.GradePointEntry(gradePoint: 2.7, count: 3),
                GradeAnalysisEntry.GradeAnalysis.GradePointEntry(gradePoint: 2.0, count: 1),
                GradeAnalysisEntry.GradeAnalysis.GradePointEntry(gradePoint: 1.7, count: 1),
                GradeAnalysisEntry.GradeAnalysis.GradePointEntry(gradePoint: 1.0, count: 1),
            ],
            semesterAverageGrades: [
                GradeAnalysisEntry.GradeAnalysis.SemesterAverageGrade(semester: "2024-2025-1", average: 88.4),
                GradeAnalysisEntry.GradeAnalysis.SemesterAverageGrade(semester: "2024-2025-2", average: 82.6),
            ],
            semesterGPAs: [
                GradeAnalysisEntry.GradeAnalysis.SemesterGPA(semester: "2024-2025-1", gpa: 3.44),
                GradeAnalysisEntry.GradeAnalysis.SemesterGPA(semester: "2024-2025-2", gpa: 3.09),
            ],
            lastUpdated: .now.addingTimeInterval(-3600)
        )
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
        let descriptor = FetchDescriptor<GradeAnalysis>(sortBy: [SortDescriptor(\.lastUpdated)])
        let context = SharedModel.context

        do {
            let gradeAnalysis = try context.fetch(descriptor).first

            if let gradeAnalysis = gradeAnalysis {
                let entry = GradeAnalysisEntry(
                    date: .now,
                    configuration: configuration,
                    gradeAnalysis: GradeAnalysisEntry.GradeAnalysis(
                        totalCourses: gradeAnalysis.totalCourses,
                        totalHours: gradeAnalysis.totalHours,
                        totalCredits: gradeAnalysis.totalCredits,
                        overallAverageGrade: gradeAnalysis.overallAverageGrade,
                        overallGPA: gradeAnalysis.overallGPA,
                        gradePointDistribution: gradeAnalysis.gradePointDistribution.map {
                            GradeAnalysisEntry.GradeAnalysis.GradePointEntry(gradePoint: $0.gradePoint, count: $0.count)
                        },
                        semesterAverageGrades: gradeAnalysis.semesterAverageGrades.map {
                            GradeAnalysisEntry.GradeAnalysis.SemesterAverageGrade(semester: $0.semester, average: $0.average)
                        },
                        semesterGPAs: gradeAnalysis.semesterGPAs.map {
                            GradeAnalysisEntry.GradeAnalysis.SemesterGPA(semester: $0.semester, gpa: $0.gpa)
                        },
                        lastUpdated: gradeAnalysis.lastUpdated
                    )
                )
                return Timeline(entries: [entry], policy: .never)
            }
        } catch {
            debugPrint("GradeAnalysisProvider: Error fetching grade analysis: \(error)")
        }
        return Timeline(entries: [GradeAnalysisEntry(date: .now, configuration: configuration, gradeAnalysis: nil)], policy: .never)
    }
}

struct GradeAnalysisEntry: TimelineEntry {
    let date: Date
    let configuration: GradeAnalysisIntent

    struct GradeAnalysis {
        struct GradePointEntry: Codable {
            var gradePoint: Double
            var count: Int
        }

        struct SemesterAverageGrade: Codable {
            var semester: String
            var average: Double
        }

        struct SemesterGPA: Codable {
            var semester: String
            var gpa: Double
        }

        let totalCourses: Int
        let totalHours: Int
        let totalCredits: Double
        let overallAverageGrade: Double
        let overallGPA: Double

        let gradePointDistribution: [GradePointEntry]
        let semesterAverageGrades: [SemesterAverageGrade]
        let semesterGPAs: [SemesterGPA]

        let lastUpdated: Date
    }

    let gradeAnalysis: GradeAnalysis?
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
