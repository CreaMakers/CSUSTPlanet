//
//  GradeQueryStatsSection.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/18.
//

import SwiftUI

struct GradeQueryStatsSection: View {
    let analysis: GradeAnalysisData?
    let isLoading: Bool

    var body: some View {
        HStack(spacing: 10) {
            if let analysis {
                GradeQueryStatItem(title: "GPA", value: String(format: "%.2f", analysis.overallGPA), color: ColorUtil.dynamicColor(point: analysis.overallGPA))
                GradeQueryStatItem(title: "平均成绩", value: String(format: "%.2f", analysis.overallAverageGrade), color: ColorUtil.dynamicColor(grade: analysis.overallAverageGrade))
                GradeQueryStatItem(title: "加权平均成绩", value: String(format: "%.2f", analysis.weightedAverageGrade), color: ColorUtil.dynamicColor(grade: analysis.weightedAverageGrade))
                GradeQueryStatItem(title: "已修总学分", value: String(format: "%.1f", analysis.totalCredits), color: .blue)
                GradeQueryStatItem(title: "课程总数", value: "\(analysis.totalCourses)", color: .purple)
            } else {
                GradeQueryStatItem(title: "GPA", value: "0.0", color: .primary)
                GradeQueryStatItem(title: "平均成绩", value: "0.0", color: .primary)
                GradeQueryStatItem(title: "加权平均成绩", value: "0.0", color: .primary)
                GradeQueryStatItem(title: "已修总学分", value: "0.0", color: .primary)
                GradeQueryStatItem(title: "课程总数", value: "0", color: .primary)
            }
        }
        .frame(maxWidth: .infinity)
        .redacted(reason: analysis == nil && isLoading ? .placeholder : [])
        .padding(.horizontal)
        .padding(.vertical)
        .apply { view in
            if #available(iOS 26.0, macOS 26.0, *) {
                view
                    .glassEffect()
                    .padding(.horizontal)
            } else {
                view.background(.ultraThinMaterial)
            }
        }
    }
}

private struct GradeQueryStatItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("GradeQueryStatsSection") {
    GradeQueryStatsSection(
        analysis: GradeAnalysisData.fromCourseGrades(GradeQueryPreviewData.grades),
        isLoading: false
    )
    .padding()
}

#Preview("GradeQueryStatsSection Loading") {
    GradeQueryStatsSection(
        analysis: nil,
        isLoading: true
    )
    .padding()
}
