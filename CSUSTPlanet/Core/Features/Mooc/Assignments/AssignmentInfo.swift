//
//  AssignmentInfo.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/20.
//

import CSUSTKit
import SwiftUI

struct AssignmentInfo: View {
    let assignment: MoocHelper.Assignment

    private var deadlineStyle: RelativeDateStyle {
        RelativeDateStyle.assignment(
            deadline: assignment.deadline,
            isSubmitted: assignment.submitStatus
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            infoRow(label: "发布人", value: assignment.publisher)
            dateRow(label: "开始时间", date: assignment.startTime, style: .secondary)
            dateRow(label: "截止时间", date: assignment.deadline, style: deadlineStyle)
        }
        .padding(.vertical, 6)
    }

    private var header: some View {
        HStack {
            Text(assignment.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)

            Spacer()

            statusIcon
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
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

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func dateRow(label: String, date: Date, style: RelativeDateStyle) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text(date, format: .dateTime.year().month().day().hour().minute())
                .font(.caption)
                .foregroundColor(style.accentColor)
            RelativeDateBadge(
                text: date.formatted(.relative(presentation: .named, unitsStyle: .abbreviated)),
                style: style,
                font: .caption2.bold(),
                horizontalPadding: 6,
                verticalPadding: 2
            )
        }
    }
}

#Preview("AssignmentInfo") {
    Form {
        AssignmentInfo(assignment: TodoAssignmentsPreviewData.unsubmittedAssignment)
        AssignmentInfo(assignment: TodoAssignmentsPreviewData.submittedAssignment)
        AssignmentInfo(assignment: TodoAssignmentsPreviewData.expiredAssignment)
    }
    .formStyle(.grouped)
}
