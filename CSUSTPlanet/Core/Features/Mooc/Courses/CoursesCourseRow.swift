//
//  CoursesCourseRow.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/22.
//

import CSUSTKit
import SwiftUI

struct CoursesCourseRow: View {
    let course: MoocHelper.Course

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(course.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let teacher = course.teacher, let department = course.department {
                    HStack(spacing: 12) {
                        infoItem(icon: "person.fill", color: .purple, text: teacher)
                        infoItem(icon: "building.columns.fill", color: .green, text: department)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .frame(width: 16)
        }
        .padding(.vertical, 6)
    }

    private func infoItem(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .imageScale(.small)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

#Preview("CoursesCourseRow") {
    Form {
        CoursesCourseRow(course: MoocCoursesPreviewData.mobileDevelopmentCourse)
        CoursesCourseRow(course: MoocCoursesPreviewData.generalEducationCourse)
    }
    .formStyle(.grouped)
}
