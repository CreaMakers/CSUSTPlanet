//
//  OverviewView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import SwiftUI

struct OverviewView: View {
    @Bindable var globalManager = GlobalManager.shared
    @State private var activeCourseSchedule = MMKVHelper.CourseSchedule.activeCourseSchedule

    private let overviewSpacing: CGFloat = 24
    private let minimumColumnWidth: CGFloat = 320

    private var overviewSubtitle: String {
        let dateText = Date().formatted(.dateTime.month().day().weekday())
        var components: [String] = []

        components.append(dateText)

        if let currentWeekText {
            components.append(currentWeekText)
        }

        return components.joined(separator: " ")
    }

    private var currentWeekText: String? {
        guard let data = activeCourseSchedule?.value.data else {
            return nil
        }

        if let currentWeek = CourseScheduleUtil.getCurrentWeek(
            semesterStartDate: data.semesterStartDate,
            now: .now,
            weekCount: data.weekCount
        ) {
            return "第\(currentWeek)周"
        }

        return nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                legacyOverviewHeader

                responsiveOverviewContent

                Spacer(minLength: 40)
            }
        }
        .navigationTitle("概览")
        .navigationSubtitleCompat(overviewSubtitle)
        .onReceive(MMKVHelper.CourseSchedule.$activeCourseSchedule) { schedule in
            activeCourseSchedule = schedule
        }
    }

    @ViewBuilder
    private var responsiveOverviewContent: some View {
        ViewThatFits(in: .horizontal) {
            WaterfallLayout(columns: 2, spacing: overviewSpacing) {
                overviewCards
            }
            .frame(minWidth: minimumColumnWidth * 2 + overviewSpacing, alignment: .top)
            .padding(.horizontal)

            WaterfallLayout(columns: 1, spacing: overviewSpacing) {
                overviewCards
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var overviewCards: some View {
        CourseOverviewView()
        GradeOverviewView()
        DormOverviewView()
        AssignmentOverviewView()
        ExamOverviewView()
        AnnouncementOverviewView()
    }

    @ViewBuilder
    private var legacyOverviewHeader: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text(overviewSubtitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 10)
        }
    }

    private func overviewColumn<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: overviewSpacing) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

struct WaterfallLayout: Layout {
    var columns: Int
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        let columnWidth = max(0, (width - spacing * CGFloat(columns - 1)) / CGFloat(columns))
        var columnHeights = Array(repeating: CGFloat.zero, count: columns)

        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil))
            let minIndex = columnHeights.firstIndex(of: columnHeights.min() ?? 0) ?? 0
            columnHeights[minIndex] += size.height + spacing
        }

        let maxHeight = (columnHeights.max() ?? 0) - (subviews.isEmpty ? 0 : spacing)
        return CGSize(width: width, height: max(0, maxHeight))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let columnWidth = max(0, (bounds.width - spacing * CGFloat(columns - 1)) / CGFloat(columns))
        var columnHeights = Array(repeating: bounds.minY, count: columns)

        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil))
            let minIndex = columnHeights.firstIndex(of: columnHeights.min() ?? bounds.minY) ?? 0

            let x = bounds.minX + CGFloat(minIndex) * (columnWidth + spacing)
            let y = columnHeights[minIndex]

            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: columnWidth, height: size.height))
            columnHeights[minIndex] += size.height + spacing
        }
    }
}
