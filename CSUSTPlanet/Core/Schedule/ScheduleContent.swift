//
//  ScheduleContent.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/9/4.
//

import SwiftUI

struct ScheduleContent: View {
    let events: [ScheduleEvent]
    let referenceDate: Date

    @State private var visibleDayID: Date?
    @State private var selectedEvent: ScheduleEvent?
    @State private var hasPerformedInitialScroll = false

    init(events: [ScheduleEvent], referenceDate: Date = .now) {
        self.events = events
        self.referenceDate = referenceDate
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(daySections) { section in
                    ScheduleDaySectionView(
                        section: section,
                        referenceDate: referenceDate,
                        onSelectEvent: { selectedEvent = $0 }
                    )
                    .id(section.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $visibleDayID, anchor: .top)
        .safeAreaInset(edge: .top, spacing: 0) {
            ScheduleDateHeader(
                dates: ScheduleDateUtil.datesForWeek(containing: activeDayID),
                activeDate: activeDayID,
                referenceDate: referenceDate,
                eventDates: Set(events.map(ScheduleDateUtil.eventDay(for:))),
                onSelectDate: scrollToNearestDate
            )
            .frame(maxWidth: 700)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("日程")
        .inlineToolbarTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("今天") {
                    scrollToNearestDate(todayID)
                }
                .disabled(ScheduleDateUtil.isSameDay(activeDayID, todayID))
            }
        }
        .onChange(of: dayIDs, initial: true) { _, _ in
            guard !hasPerformedInitialScroll, dayIDs.contains(todayID) else {
                return
            }

            hasPerformedInitialScroll = true
            visibleDayID = todayID
        }
        .sheet(item: $selectedEvent) { event in
            NavigationStack {
                ScheduleEventDetailView(event: event)
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var daySections: [ScheduleDaySection] {
        var groupedEvents: [Date: [ScheduleEvent]] = [:]

        for event in events {
            groupedEvents[ScheduleDateUtil.eventDay(for: event), default: []].append(event)
        }

        let today = todayID
        if groupedEvents[today] == nil {
            groupedEvents[today] = []
        }

        return groupedEvents.keys.sorted().map { day in
            let sortedEvents = groupedEvents[day, default: []].sorted {
                if $0.timing.anchorDate != $1.timing.anchorDate {
                    return $0.timing.anchorDate < $1.timing.anchorDate
                }

                if $0.kind.presentationSortPriority != $1.kind.presentationSortPriority {
                    return $0.kind.presentationSortPriority < $1.kind.presentationSortPriority
                }

                return $0.id < $1.id
            }

            return ScheduleDaySection(id: day, events: sortedEvents)
        }
    }

    private var dayIDs: [Date] {
        daySections.map(\.id)
    }

    private var todayID: Date {
        ScheduleDateUtil.startOfDay(for: referenceDate)
    }

    private var activeDayID: Date {
        guard let visibleDayID, dayIDs.contains(visibleDayID) else {
            return todayID
        }

        return visibleDayID
    }

    private func scrollToNearestDate(_ date: Date) {
        guard
            let targetDate = dayIDs.min(by: { lhs, rhs in
                abs(lhs.timeIntervalSince(date)) < abs(rhs.timeIntervalSince(date))
            })
        else {
            return
        }

        withAnimation(.easeInOut) {
            visibleDayID = targetDate
        }
    }
}

private struct ScheduleDaySection: Identifiable {
    let id: Date
    let events: [ScheduleEvent]
}

private struct ScheduleDaySectionView: View {
    let section: ScheduleDaySection
    let referenceDate: Date
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

            if section.events.isEmpty {
                ContentUnavailableView {
                    Label("今天暂无日程", systemImage: "calendar.badge.checkmark")
                } description: {
                    Text("可以先看看其他日期的课程和安排")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
            } else {
                VStack(spacing: 8) {
                    ForEach(section.events) { event in
                        ScheduleEventRow(event: event) {
                            onSelectEvent(event)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

#Preview("ScheduleContent") {
    NavigationStack {
        ScheduleContent(
            events: SchedulePreviewData.events,
            referenceDate: SchedulePreviewData.referenceDate
        )
    }
}

#Preview("ScheduleContent - Empty") {
    NavigationStack {
        ScheduleContent(
            events: [],
            referenceDate: SchedulePreviewData.referenceDate
        )
    }
}
