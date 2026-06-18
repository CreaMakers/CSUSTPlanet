//
//  GradeDetailScoreSummary.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/18.
//

import CSUSTKit
import SwiftUI

struct GradeDetailScoreSummary: View {
    let courseGrade: EduHelper.CourseGrade

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(courseGrade.courseName)
                .font(.largeTitle)
                .bold()
                .padding(.horizontal)

            HStack(alignment: .top, spacing: 16) {
                GradeDetailScoreItem(value: "\(courseGrade.grade)", label: "总成绩", color: ColorUtil.dynamicColor(grade: Double(courseGrade.grade)))
                GradeDetailScoreItem(value: String(format: "%.1f", courseGrade.gradePoint), label: "绩点", color: ColorUtil.dynamicColor(point: courseGrade.gradePoint))
                GradeDetailScoreItem(value: String(format: "%.1f", courseGrade.credit), label: "学分", color: .primary)
                GradeDetailScoreItem(value: "\(courseGrade.totalHours)", label: "学时", color: .primary)
            }
            .padding(.horizontal)
        }
    }
}

private struct GradeDetailScoreItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(label)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("GradeDetailScoreSummary") {
    GradeDetailScoreSummary(courseGrade: GradeQueryPreviewData.grades[0])
        .padding()
}
