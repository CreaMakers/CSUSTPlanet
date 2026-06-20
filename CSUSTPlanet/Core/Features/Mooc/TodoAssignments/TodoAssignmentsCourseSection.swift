//
//  TodoAssignmentsCourseSection.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/20.
//

import CSUSTKit
import SwiftUI

struct TodoAssignmentsCourseSection: View {
    let group: TodoAssignmentsData
    let referenceDate: Date
    @Binding var isExpanded: Bool
    @Binding var isShowingAllAssignments: Bool
    let onOpenCoursePage: (String) -> Void

    private var submittableAssignments: [MoocHelper.Assignment] {
        group.assignments.filter { $0.isSubmittable(referenceDate: referenceDate) }
    }

    private var displayedAssignments: [MoocHelper.Assignment] {
        if isShowingAllAssignments {
            return group.assignments
        }
        return submittableAssignments
    }

    private var hasHiddenAssignments: Bool {
        displayedAssignments.count < group.assignments.count
    }

    var body: some View {
        CustomGroupBox {
            VStack {
                header

                if isExpanded {
                    ForEach(displayedAssignments.indices, id: \.self) { index in
                        Divider()
                        AssignmentInfoView(assignment: displayedAssignments[index])
                    }

                    if hasHiddenAssignments || isShowingAllAssignments {
                        Divider()
                        Button {
                            isShowingAllAssignments.toggle()
                        } label: {
                            HStack(spacing: 6) {
                                Text(isShowingAllAssignments ? "仅可提交" : "查看全部")
                                Image(systemName: isShowingAllAssignments ? "chevron.up" : "chevron.down")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            HStack {
                Image(systemName: "chevron.right")
                    .frame(width: 16, height: 16, alignment: .leading)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0), anchor: .center)

                Text(group.course.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                VStack(alignment: .trailing) {
                    Text("\(group.assignments.count)个作业")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(submittableAssignments.count)个可提交")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .contentShape(.rect)
            .onTapGesture {
                isExpanded.toggle()
            }

            Button {
                onOpenCoursePage(group.course.id)
            } label: {
                Text("前往课程")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
}

extension MoocHelper.Assignment {
    func isSubmittable(referenceDate: Date) -> Bool {
        canSubmit && !submitStatus && deadline >= referenceDate
    }
}

#Preview("TodoAssignmentsCourseSection") {
    @Previewable @State var isExpanded = true
    @Previewable @State var isShowingAllAssignments = false

    NavigationStack {
        CustomScrollView {
            TodoAssignmentsCourseSection(
                group: TodoAssignmentsPreviewData.groups[0],
                referenceDate: TodoAssignmentsPreviewData.referenceDate,
                isExpanded: $isExpanded,
                isShowingAllAssignments: $isShowingAllAssignments,
                onOpenCoursePage: { _ in }
            )
            .padding()
        }
    }
}

#Preview("TodoAssignmentsCourseSection All") {
    @Previewable @State var isExpanded = true
    @Previewable @State var isShowingAllAssignments = true

    CustomScrollView {
        TodoAssignmentsCourseSection(
            group: TodoAssignmentsPreviewData.groups[0],
            referenceDate: TodoAssignmentsPreviewData.referenceDate,
            isExpanded: $isExpanded,
            isShowingAllAssignments: $isShowingAllAssignments,
            onOpenCoursePage: { _ in }
        )
        .padding()
    }
}
