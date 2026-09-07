//
//  ScheduleEmptySectionView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/9/7.
//

import SwiftUI

struct ScheduleEmptySectionView: View {
    let section: ScheduleEmptySection
    let referenceDate: Date
    let showsIndicator: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .font(.headline.weight(.semibold))

                if section.dayCount > 1 {
                    Spacer(minLength: 8)

                    Text("连续 \(section.dayCount) 天")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 8)

            VStack(spacing: 12) {
                if showsIndicator {
                    ScheduleCurrentTimeIndicator()
                }

                Text("暂无日程")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var title: String {
        if section.dayCount == 1 {
            if let relativeDayTitle = ScheduleDateUtil.relativeDayTitle(
                for: section.startDate,
                referenceDate: referenceDate
            ) {
                return "\(relativeDayTitle) · \(ScheduleDateUtil.dateWithWeekdayFormatter.string(from: section.startDate))"
            }

            return ScheduleDateUtil.dateWithWeekdayFormatter.string(from: section.startDate)
        }

        let start = ScheduleDateUtil.dateWithWeekdayFormatter.string(from: section.startDate)
        let end = ScheduleDateUtil.dateWithWeekdayFormatter.string(from: section.endDate)
        return "\(start) — \(end)"
    }
}

#Preview("ScheduleEmptySectionView") {
    let referenceDate = SchedulePreviewData.referenceDate
    let today = ScheduleDateUtil.startOfDay(for: referenceDate)
    let futureStart = ScheduleDateUtil.calendar.date(byAdding: .day, value: 2, to: today)!
    let futureEnd = ScheduleDateUtil.calendar.date(byAdding: .day, value: 4, to: today)!

    VStack(spacing: 0) {
        ScheduleEmptySectionView(
            section: ScheduleEmptySection(startDate: today, endDate: today),
            referenceDate: referenceDate,
            showsIndicator: true
        )

        Divider()

        ScheduleEmptySectionView(
            section: ScheduleEmptySection(startDate: futureStart, endDate: futureEnd),
            referenceDate: referenceDate,
            showsIndicator: false
        )
    }
}
