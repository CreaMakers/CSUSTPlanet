//
//  GradeQueryGradeRow.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/18.
//

import CSUSTKit
import SwiftUI

struct GradeQueryGradeRow: View {
    let courseGrade: EduHelper.CourseGrade
    let isSelectionMode: Bool
    @Binding var isSelected: Bool

    var body: some View {
        if isSelectionMode {
            Button {
                isSelected.toggle()
            } label: {
                GradeQueryGradeRowContent(courseGrade: courseGrade)
                    .contentShape(.rect)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? Color.gray.opacity(0.2) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: AppRoute.features(.education(.gradeQuery(.detail(courseGrade))))) {
                GradeQueryGradeRowContent(courseGrade: courseGrade)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct GradeQueryGradeRowContent: View {
    let courseGrade: EduHelper.CourseGrade

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(courseGrade.courseAttribute)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.2))
                        .foregroundColor(Color.accentColor)
                        .cornerRadius(4)

                    Text(courseGrade.courseName)
                        .font(.headline)
                }

                if !courseGrade.groupName.isEmpty {
                    Text("(\(courseGrade.groupName))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 20) {
                    HStack(spacing: 4) {
                        Text("学分：")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", courseGrade.credit))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 4) {
                        Text("绩点：")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", courseGrade.gradePoint))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(ColorUtil.dynamicColor(point: courseGrade.gradePoint))
                    }
                }
            }

            Spacer()

            Text("\(courseGrade.grade)分")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(ColorUtil.dynamicColor(grade: Double(courseGrade.grade)))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
    }
}

#Preview("GradeQueryGradeRow") {
    NavigationStack {
        GradeQueryGradeRow(
            courseGrade: GradeQueryPreviewData.grades[0],
            isSelectionMode: false,
            isSelected: .constant(false)
        )
        .padding()
    }
}

#Preview("GradeQueryGradeRow Selection") {
    GradeQueryGradeRow(
        courseGrade: GradeQueryPreviewData.grades[0],
        isSelectionMode: true,
        isSelected: .constant(true)
    )
    .padding()
}
