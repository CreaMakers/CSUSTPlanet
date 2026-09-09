//
//  ScheduleDateHeader.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/9/4.
//

import SwiftUI

struct ScheduleDateHeader: View {
    let dates: [Date]
    let activeDate: Date
    let referenceDate: Date
    let eventDates: Set<Date>
    let onSelectDate: (Date) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(dates, id: \.self) { date in
                dateButton(for: date)
            }
        }
        .apply { view in
            if #unavailable(iOS 26.0, macOS 26.0) {
                view.frame(minWidth: 700)
            } else {
                view
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .apply { view in
            if #available(iOS 26.0, macOS 26.0, *) {
                view
                    .glassEffect()
                    .padding(.horizontal, 8)
            } else {
                view.background(.ultraThinMaterial)
            }
        }
        .apply { view in
            if #available(iOS 26.0, macOS 26.0, *) {
                view.frame(maxWidth: 700)
            } else {
                view
            }
        }
    }

    private func dateButton(for date: Date) -> some View {
        let isActive = ScheduleDateUtil.isSameDay(date, activeDate)
        let isToday = ScheduleDateUtil.isSameDay(date, referenceDate)
        let hasEvents = eventDates.contains(ScheduleDateUtil.startOfDay(for: date))

        return Button {
            onSelectDate(date)
        } label: {
            VStack(spacing: 2) {
                Text(ScheduleDateUtil.weekdayFormatter.string(from: date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                ZStack {
                    if isToday && !isActive {
                        Circle()
                            .stroke(Color.accentColor.opacity(0.45), lineWidth: 1)
                            .frame(width: 30, height: 30)
                    }

                    Text(ScheduleDateUtil.dayNumberFormatter.string(from: date))
                        .font(.body.weight(isActive ? .semibold : .regular))
                        .foregroundStyle(isActive ? Color.white : Color.primary)
                        .frame(width: 32, height: 32)
                        .background {
                            if isActive {
                                Circle()
                                    .fill(Color.accentColor)
                            }
                        }
                }

                ZStack {
                    if hasEvents {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 4, height: 4)
                    } else if isToday {
                        Circle()
                            .stroke(Color.accentColor.opacity(0.5), lineWidth: 1.5)
                            .frame(width: 5, height: 5)
                    } else {
                        Color.clear
                            .frame(width: 5, height: 5)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("ScheduleDateHeader") {
    let referenceDate = SchedulePreviewData.referenceDate
    let activeDate = ScheduleDateUtil.startOfDay(for: referenceDate)

    ScheduleDateHeader(
        dates: ScheduleDateUtil.datesForWeek(containing: referenceDate),
        activeDate: activeDate,
        referenceDate: referenceDate,
        eventDates: Set(SchedulePreviewData.events.map(ScheduleDateUtil.eventDay(for:))),
        onSelectDate: { _ in }
    )
}
