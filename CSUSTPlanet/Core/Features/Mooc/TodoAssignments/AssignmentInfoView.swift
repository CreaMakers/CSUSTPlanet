//
//  AssignmentInfoView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/20.
//

import CSUSTKit
import SwiftUI

struct AssignmentInfoView: View {
    let assignment: MoocHelper.Assignment

    private var deadlineStyle: RelativeDateStyle {
        RelativeDateStyle.assignment(
            deadline: assignment.deadline,
            isSubmitted: assignment.submitStatus
        )
    }

    @ViewBuilder
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(assignment.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                Spacer()

                if assignment.submitStatus {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                } else if assignment.canSubmit {
                    Image(systemName: "circle")
                        .foregroundColor(.orange)
                        .font(.caption)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            HStack {
                Text("发布人")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(assignment.publisher)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("开始时间")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(assignment.startTime, format: .dateTime.year().month().day().hour().minute())
                    .font(.caption)
                    .foregroundColor(.secondary)
                RelativeDateBadge(
                    text: assignment.startTime.formatted(.relative(presentation: .named, unitsStyle: .abbreviated)),
                    style: .secondary,
                    font: .caption2.bold(),
                    horizontalPadding: 6,
                    verticalPadding: 2
                )
            }

            HStack {
                Text("截止时间")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(assignment.deadline, format: .dateTime.year().month().day().hour().minute())
                    .font(.caption)
                    .foregroundColor(deadlineStyle.accentColor)
                RelativeDateBadge(
                    text: assignment.deadline.formatted(.relative(presentation: .named, unitsStyle: .abbreviated)),
                    style: deadlineStyle,
                    font: .caption2.bold(),
                    horizontalPadding: 6,
                    verticalPadding: 2
                )
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview("AssignmentInfoView") {
    Form {
        AssignmentInfoView(assignment: TodoAssignmentsPreviewData.unsubmittedAssignment)
        AssignmentInfoView(assignment: TodoAssignmentsPreviewData.submittedAssignment)
        AssignmentInfoView(assignment: TodoAssignmentsPreviewData.expiredAssignment)
    }
    .formStyle(.grouped)
}
