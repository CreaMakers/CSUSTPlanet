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
    let onOpenCoursePage: (String) -> Void

    @State private var isExpanded = true
    @State private var isAllAssignmentsPresented = false

    private var submittableAssignments: [MoocHelper.Assignment] {
        let referenceDate = Date.now
        return group.assignments.filter { $0.isSubmittable(referenceDate: referenceDate) }
    }

    private var displayedAssignments: [MoocHelper.Assignment] {
        if isAllAssignmentsPresented {
            return group.assignments
        }
        return submittableAssignments
    }

    private var hasHiddenAssignments: Bool {
        submittableAssignments.count < group.assignments.count
    }

    var body: some View {
        CustomGroupBox {
            VStack {
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
                        withAnimation {
                            isExpanded.toggle()
                        }
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

                if isExpanded {
                    ForEach(displayedAssignments, id: \.id) { assignment in
                        Divider()
                        AssignmentInfo(assignment: assignment)
                    }

                    if hasHiddenAssignments || isAllAssignmentsPresented {
                        Divider()
                        Button {
                            withAnimation {
                                isAllAssignmentsPresented.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(isAllAssignmentsPresented ? "仅可提交" : "查看全部")
                                Image(systemName: isAllAssignmentsPresented ? "chevron.up" : "chevron.down")
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
}

extension MoocHelper.Assignment {
    func isSubmittable(referenceDate: Date = .now) -> Bool {
        canSubmit && !submitStatus && deadline >= referenceDate
    }
}

#Preview("TodoAssignmentsCourseSection") {
    NavigationStack {
        CustomScrollView {
            TodoAssignmentsCourseSection(
                group: TodoAssignmentsPreviewData.groups[0],
                onOpenCoursePage: { _ in }
            )
            .padding()
        }
    }
}
