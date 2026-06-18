//
//  GradeQuerySectionList.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/18.
//

import CSUSTKit
import SwiftUI

struct GradeQuerySectionList: View {
    let groupedGrades: [(semester: String, grades: [EduHelper.CourseGrade])]
    let expandedSemesters: Set<String>
    let semesterGPAs: [String: Double]
    let isSelectionMode: Bool
    let selectedCourseIDs: Set<String>
    let onToggleSemester: (String) -> Void
    let onToggleSelection: (String) -> Void

    var body: some View {
        CustomScrollView {
            ForEach(groupedGrades, id: \.semester) { group in
                let isExpanded = expandedSemesters.contains(group.semester)
                CustomGroupBox {
                    VStack {
                        HStack {
                            Image(systemName: "chevron.right")
                                .frame(width: 16, height: 16, alignment: .leading)
                                .rotationEffect(.degrees(isExpanded ? 90 : 0))

                            Text(group.semester)
                                .font(.headline)
                                .foregroundColor(.primary)

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text("\(group.grades.count)门课程")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("学期GPA: \(semesterGPAs[group.semester] ?? 0.0, specifier: "%.2f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .contentShape(.rect)
                        .onTapGesture(perform: { onToggleSemester(group.semester) })

                        if isExpanded {
                            ForEach(group.grades, id: \.courseID) { courseGrade in
                                Divider()
                                GradeQueryGradeRow(
                                    courseGrade: courseGrade,
                                    isSelectionMode: isSelectionMode,
                                    isSelected: selectedCourseIDs.contains(courseGrade.courseID),
                                    onToggleSelection: { onToggleSelection(courseGrade.courseID) }
                                )
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

#Preview("GradeQuerySectionList") {
    @Previewable @State var expandedSemesters: Set<String> = Set(GradeQueryPreviewData.grades.map { $0.semester })

    NavigationStack {
        GradeQuerySectionList(
            groupedGrades: GradeQueryPreviewData.groupedGrades,
            expandedSemesters: expandedSemesters,
            semesterGPAs: GradeQueryPreviewData.semesterGPAs,
            isSelectionMode: false,
            selectedCourseIDs: [],
            onToggleSemester: { semester in
                withAnimation {
                    if expandedSemesters.contains(semester) {
                        expandedSemesters.remove(semester)
                    } else {
                        expandedSemesters.insert(semester)
                    }
                }
            },
            onToggleSelection: { _ in }
        )
    }
}

#Preview("GradeQuerySectionList Selection") {
    NavigationStack {
        GradeQuerySectionList(
            groupedGrades: GradeQueryPreviewData.groupedGrades,
            expandedSemesters: Set(GradeQueryPreviewData.grades.map { $0.semester }),
            semesterGPAs: GradeQueryPreviewData.semesterGPAs,
            isSelectionMode: true,
            selectedCourseIDs: [GradeQueryPreviewData.grades[0].courseID],
            onToggleSemester: { _ in },
            onToggleSelection: { _ in }
        )
    }
}
