//
//  ScheduleDaySectionView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/9/7.
//

import SwiftUI

struct ScheduleDaySectionView: View {
    let section: ScheduleDaySection
    let referenceDate: Date
    let currentIndicatorPlacement: ScheduleCurrentIndicatorPlacement?
    let onSelectEvent: (ScheduleEvent) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if let relativeDayTitle = ScheduleDateUtil.relativeDayTitle(
                    for: section.id,
                    referenceDate: referenceDate
                ) {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text(relativeDayTitle)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(
                                relativeDayTitle == "今天" ? Color.accentColor : Color.primary
                            )

                        Text(
                            " · \(ScheduleDateUtil.dateWithWeekdayFormatter.string(from: section.id))"
                        )
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                    }
                } else {
                    Text(ScheduleDateUtil.dateWithWeekdayFormatter.string(from: section.id))
                        .font(.headline.weight(.semibold))
                }

                Spacer(minLength: 8)

                if !section.events.isEmpty {
                    Text("\(section.events.count) 项")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(Array(section.events.enumerated()), id: \.element.id) { index, event in
                    if showsIndicator(before: event) {
                        ScheduleCurrentTimeIndicator()
                    } else if index > 0 {
                        Color.clear
                            .frame(height: 8)
                            .accessibilityHidden(true)
                    }

                    ScheduleEventRow(
                        event: event,
                        isEnded: event.isEnded(at: referenceDate),
                        onTap: {
                            onSelectEvent(event)
                        }
                    )
                }

                if showsIndicatorAfterEvents {
                    ScheduleCurrentTimeIndicator()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private func showsIndicator(before event: ScheduleEvent) -> Bool {
        guard case .some(.beforeEvent(let eventID)) = currentIndicatorPlacement else {
            return false
        }

        return event.id == eventID
    }

    private var showsIndicatorAfterEvents: Bool {
        guard case .some(.afterDay(let day)) = currentIndicatorPlacement else {
            return false
        }

        return ScheduleDateUtil.isSameDay(day, section.id)
    }
}

#Preview("ScheduleDaySectionView") {
    let referenceDate = SchedulePreviewData.referenceDate
    let section = ScheduleDaySection(
        id: ScheduleDateUtil.startOfDay(for: referenceDate),
        events: Array(SchedulePreviewData.events.prefix(3))
    )

    ScheduleDaySectionView(
        section: section,
        referenceDate: referenceDate,
        currentIndicatorPlacement: .beforeEvent(SchedulePreviewData.events[1].id),
        onSelectEvent: { _ in }
    )
    .fixedSize(horizontal: false, vertical: true)
}
