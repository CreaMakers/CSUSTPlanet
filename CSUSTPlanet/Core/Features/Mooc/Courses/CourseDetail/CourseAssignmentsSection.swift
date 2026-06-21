//
//  CourseAssignmentsSection.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/21.
//

import CSUSTKit
import SwiftUI

struct CourseAssignmentsSection: View {
    let assignments: [MoocHelper.Assignment]
    let isLoading: Bool
    let onRefresh: () async -> Void

    @State private var isShowingAllAssignments = false

    private var submittableAssignments: [MoocHelper.Assignment] {
        let referenceDate = Date.now
        return assignments.filter { $0.isSubmittable(referenceDate: referenceDate) }
    }

    private var displayedAssignments: [MoocHelper.Assignment] {
        if isShowingAllAssignments {
            return assignments
        }

        return submittableAssignments
    }

    private var hasHiddenAssignments: Bool {
        submittableAssignments.count < assignments.count
    }

    var body: some View {
        CustomGroupBox {
            VStack {
                HStack {
                    HStack {
                        Text("作业列表")
                            .font(.headline)

                        if isLoading {
                            ProgressView().smallControlSizeOnMac()
                        } else {
                            Button(asyncAction: onRefresh) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.subheadline)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("\(assignments.count)个作业")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(submittableAssignments.count)个可提交")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if displayedAssignments.isEmpty {
                    Divider()
                    ContentUnavailableView("暂无作业", systemImage: "list.bullet.clipboard")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                } else {
                    ForEach(displayedAssignments, id: \.id) { assignment in
                        Divider()
                        AssignmentInfo(assignment: assignment)
                    }
                }

                if hasHiddenAssignments || isShowingAllAssignments {
                    Divider()
                    Button {
                        withAnimation {
                            isShowingAllAssignments.toggle()
                        }
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

#Preview("CourseAssignmentsSection") {
    CustomScrollView {
        CourseAssignmentsSection(
            assignments: MoocCoursesPreviewData.assignments,
            isLoading: false,
            onRefresh: {}
        )
        .padding()
    }
}

#Preview("CourseAssignmentsSection Empty") {
    CustomScrollView {
        CourseAssignmentsSection(
            assignments: [],
            isLoading: false,
            onRefresh: {}
        )
        .padding()
    }
}
