//
//  GradeDetailInfoSection.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/18.
//

import CSUSTKit
import SwiftUI

struct GradeDetailInfoSection: View {
    let courseGrade: EduHelper.CourseGrade

    var body: some View {
        CustomGroupBox {
            VStack(alignment: .leading, spacing: 12) {
                GradeDetailInfoRow(label: "课程编号", value: courseGrade.courseID)
                GradeDetailInfoRow(label: "开课学期", value: courseGrade.semester)
                if !courseGrade.groupName.isEmpty {
                    GradeDetailInfoRow(label: "分组名", value: courseGrade.groupName)
                }
                GradeDetailInfoRow(label: "修读方式", value: courseGrade.studyMode)
                GradeDetailInfoRow(label: "课程性质", value: courseGrade.courseNature.rawValue)
                if !courseGrade.courseCategory.isEmpty {
                    GradeDetailInfoRow(label: "课程类别", value: courseGrade.courseCategory)
                }
                GradeDetailInfoRow(label: "课程属性", value: courseGrade.courseAttribute)
                GradeDetailInfoRow(label: "考核方式", value: courseGrade.assessmentMethod)
                GradeDetailInfoRow(label: "考试性质", value: courseGrade.examNature)
            }
        }
    }
}

private struct GradeDetailInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.callout)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .font(.callout)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview("GradeDetailInfoSection") {
    GradeDetailInfoSection(courseGrade: GradeQueryPreviewData.grades[0])
        .padding()
}
