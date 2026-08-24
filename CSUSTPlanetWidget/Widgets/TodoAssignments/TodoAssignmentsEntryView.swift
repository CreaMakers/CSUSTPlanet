//
//  TodoAssignmentsEntryView.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zachary Liu on 2026/3/27.
//

import CSUSTKit
import SwiftUI
import WidgetKit

struct TodoAssignmentsEntryView: View {
    @Environment(\.widgetFamily) private var family

    var entry: TodoAssignmentsProvider.Entry

    var body: some View {
        Group {
            if let data = entry.data, let lastUpdated = entry.lastUpdated {
                contentView(data: data, lastUpdated: lastUpdated)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ZStack(alignment: .topTrailing) {
                    emptyView.frame(maxWidth: .infinity, maxHeight: .infinity)
                    refreshButtonView
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .widgetURL(URL(string: "csustplanet://features/todo-assignments"))
        .containerBackground(.fill.tertiary, for: .widget)
    }

    @ViewBuilder
    private func contentView(data: [TodoAssignmentsData], lastUpdated: Date) -> some View {
        let summary = displaySummary(from: data)

        VStack(spacing: 0) {
            headerView(summary: summary, lastUpdated: lastUpdated)
            Divider().padding(.vertical, 4)

            if summary.totalAssignments == 0 {
                emptyAssignmentsView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                GeometryReader { proxy in
                    let rowHeight = rowHeight(for: proxy.size.height, rowCount: maxContentRows)

                    VStack(alignment: .leading, spacing: rowSpacing) {
                        ForEach(summary.contentItems, id: \.assignment.id) { item in
                            assignmentRowView(item: item)
                                .frame(height: rowHeight, alignment: .leading)
                        }

                        if summary.showsOverflowInContent {
                            overflowRowView(remainingAssignments: summary.remainingAssignments)
                                .frame(height: rowHeight, alignment: .leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            footerView(lastUpdated: lastUpdated)
        }
    }

    private func displaySummary(from data: [TodoAssignmentsData]) -> DisplaySummary {
        let referenceDate = Date.now
        let items =
            data
            .flatMap { group in
                group.assignments
                    .filter { $0.deadline >= referenceDate }
                    .filter { $0.canSubmit && !$0.submitStatus }
                    .map { DisplayAssignmentItem(courseName: group.course.name, assignment: $0) }
            }
            .sorted { $0.assignment.deadline < $1.assignment.deadline }

        let maxContentRows = self.maxContentRows
        let showsOverflowInHeader = family == .systemMedium && items.count > maxContentRows
        let showsOverflowInContent = family == .systemSmall && items.count > maxContentRows
        let maxVisibleAssignments = showsOverflowInContent ? maxContentRows - 1 : maxContentRows
        let displayedItems = Array(items.prefix(maxVisibleAssignments))

        return DisplaySummary(
            contentItems: displayedItems,
            totalAssignments: items.count,
            remainingAssignments: max(0, items.count - displayedItems.count),
            showsOverflowInHeader: showsOverflowInHeader || (family == .systemLarge && items.count > maxContentRows),
            showsOverflowInContent: showsOverflowInContent
        )
    }

    @ViewBuilder
    private func headerView(summary: DisplaySummary, lastUpdated: Date) -> some View {
        HStack(alignment: .center, spacing: 4) {
            Text("待提交作业")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.primary)

            Text("\(summary.totalAssignments)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(.red)

            if family != .systemSmall {
                LastUpdatedDateView(
                    lastUpdated: lastUpdated,
                    font: .system(size: 10, weight: .medium),
                    foregroundStyle: .secondary
                )
            }

            Spacer()

            if summary.showsOverflowInHeader {
                Text("还有 \(summary.remainingAssignments) 个未展示")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            refreshButtonView
        }
    }

    @ViewBuilder
    private func assignmentRowView(item: DisplayAssignmentItem) -> some View {
        if family == .systemLarge {
            largeAssignmentCardView(item: item)
        } else {
            HStack(alignment: .center, spacing: 0) {
                if family == .systemMedium {
                    HStack(alignment: .center, spacing: 2) {
                        Text(item.assignment.title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .layoutPriority(1)

                        Text(item.courseName)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(item.assignment.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                deadlineBadge(for: item.assignment)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func largeAssignmentCardView(item: DisplayAssignmentItem) -> some View {
        let deadlineStyle = RelativeDateStyle.assignment(
            deadline: item.assignment.deadline,
            isSubmitted: item.assignment.submitStatus
        )

        HStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 2)
                .fill(deadlineStyle.accentColor)
                .frame(width: 4)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.assignment.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(item.courseName)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 2)

                VStack(alignment: .trailing, spacing: 4) {
                    RelativeDateBadge(
                        text: item.assignment.deadline.formatted(.relative(presentation: .named, unitsStyle: .abbreviated)),
                        style: deadlineStyle,
                        font: .system(size: 11, weight: .bold),
                        horizontalPadding: 7,
                        verticalPadding: 3
                    )
                    .lineLimit(1)

                    Text(item.assignment.deadline, format: .dateTime.month().day().hour().minute())
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                .padding(.trailing, 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(deadlineStyle.cardBackgroundColor)
            .cornerRadius(4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func deadlineBadge(for assignment: MoocHelper.Assignment) -> some View {
        RelativeDateBadge(
            text: assignment.deadline.formatted(.relative(presentation: .named, unitsStyle: .abbreviated)),
            style: RelativeDateStyle.assignment(
                deadline: assignment.deadline,
                isSubmitted: assignment.submitStatus
            ),
            font: .caption2.bold(),
            horizontalPadding: 6,
            verticalPadding: 2
        )
        .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private func overflowRowView(remainingAssignments: Int) -> some View {
        Text("还有 \(remainingAssignments) 个作业未展示")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.clipboard")
                .font(.title)
                .foregroundStyle(.gray.opacity(0.8))

            VStack(spacing: 4) {
                Text("暂无作业数据")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("请点击右上角刷新按钮尝试刷新作业数据")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var emptyAssignmentsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: family == .systemMedium ? 22 : 18))
                .foregroundStyle(.green)

            Text("暂无未截止作业")
                .font(.system(size: family == .systemMedium ? 14 : 13, weight: .semibold))
                .foregroundStyle(.primary)
        }
    }

    var refreshButtonView: some View {
        Button(intent: RefreshTodoAssignmentsTimelineIntent()) {
            Image(systemName: "arrow.clockwise.circle")
        }
        .foregroundStyle(Color.accentColor)
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func footerView(lastUpdated: Date) -> some View {
        if family == .systemSmall {
            LastUpdatedDateView(
                lastUpdated: lastUpdated,
                font: .system(size: 10, weight: .medium),
                foregroundStyle: .secondary
            )
            .multilineTextAlignment(.center)
            .padding(.top, 4)
        }
    }

    private var rowSpacing: CGFloat {
        switch family {
        case .systemSmall:
            return 3
        case .systemMedium:
            return 4
        default:
            return 5
        }
    }

    private var maxContentRows: Int {
        switch family {
        case .systemSmall:
            return 4
        case .systemLarge:
            return 6
        default:
            return 5
        }
    }

    private func rowHeight(for availableHeight: CGFloat, rowCount: Int) -> CGFloat {
        guard rowCount > 0 else { return 0 }

        let totalSpacing = rowSpacing * CGFloat(max(0, rowCount - 1))
        return max(0, (availableHeight - totalSpacing) / CGFloat(rowCount))
    }

}

private struct DisplaySummary {
    let contentItems: [DisplayAssignmentItem]
    let totalAssignments: Int
    let remainingAssignments: Int
    let showsOverflowInHeader: Bool
    let showsOverflowInContent: Bool
}

private struct DisplayAssignmentItem {
    let courseName: String
    let assignment: MoocHelper.Assignment
}
