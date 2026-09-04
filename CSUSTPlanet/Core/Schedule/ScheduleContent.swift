//
//  ScheduleContent.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/9/4.
//

import SwiftUI

struct ScheduleContent: View {
    let events: [ScheduleEvent]

    @Environment(\.scenePhase) private var scenePhase
    @State private var referenceDate: Date
    @State private var visibleDayID: Date?
    @State private var selectedEvent: ScheduleEvent?
    @State private var hasPerformedInitialScroll = false

    private let refreshesReferenceDate: Bool

    init(events: [ScheduleEvent], referenceDate: Date? = nil) {
        self.events = events
        refreshesReferenceDate = referenceDate == nil
        _referenceDate = State(initialValue: referenceDate ?? .now)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(daySections) { section in
                    ScheduleDaySectionView(
                        section: section,
                        referenceDate: referenceDate,
                        currentIndicatorEventID: currentIndicatorEventID,
                        showsIndicatorAfterEvents: shouldShowIndicatorAfterLastEvent
                            && section.events.last?.id == sortedEvents.last?.id,
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
        .task(id: scenePhase) {
            guard refreshesReferenceDate, scenePhase == .active else {
                return
            }

            await refreshReferenceDate()
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

        for event in sortedEvents {
            groupedEvents[ScheduleDateUtil.eventDay(for: event), default: []].append(event)
        }

        return groupedEvents.keys.sorted().map { day in
            return ScheduleDaySection(id: day, events: groupedEvents[day, default: []])
        }
    }

    private var sortedEvents: [ScheduleEvent] {
        events.sorted { lhs, rhs in
            if lhs.timing.anchorDate != rhs.timing.anchorDate {
                return lhs.timing.anchorDate < rhs.timing.anchorDate
            }

            if lhs.kind.presentationSortPriority != rhs.kind.presentationSortPriority {
                return lhs.kind.presentationSortPriority < rhs.kind.presentationSortPriority
            }

            return lhs.id < rhs.id
        }
    }

    private var currentIndicatorEventID: String? {
        guard !sortedEvents.isEmpty else {
            return nil
        }

        if let currentEvent = sortedEvents.first(where: isCurrentEvent(_:)) {
            return currentEvent.id
        }

        return sortedEvents.first { event in
            event.timing.anchorDate >= referenceDate
        }?.id
    }

    private var shouldShowIndicatorAfterLastEvent: Bool {
        !sortedEvents.isEmpty && currentIndicatorEventID == nil
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

        withAnimation {
            visibleDayID = targetDate
        }
    }

    private func isCurrentEvent(_ event: ScheduleEvent) -> Bool {
        guard case .interval(let start, let end) = event.timing else {
            return false
        }

        return start <= referenceDate && referenceDate < end
    }

    private func refreshReferenceDate() async {
        while !Task.isCancelled {
            let now = Date.now
            referenceDate = now

            guard
                let startOfMinute = ScheduleDateUtil.calendar.date(
                    bySetting: .second,
                    value: 0,
                    of: now
                ),
                let nextMinute = ScheduleDateUtil.calendar.date(
                    byAdding: .minute,
                    value: 1,
                    to: startOfMinute
                )
            else {
                return
            }

            let delay = max(nextMinute.timeIntervalSince(now), 0.1)

            do {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            } catch {
                return
            }
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
    let currentIndicatorEventID: String?
    let showsIndicatorAfterEvents: Bool
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
                    if event.id == currentIndicatorEventID {
                        ScheduleCurrentTimeIndicator()
                    } else if index > 0 {
                        Color.clear
                            .frame(height: 8)
                            .accessibilityHidden(true)
                    }

                    ScheduleEventRow(event: event) {
                        onSelectEvent(event)
                    }
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
}

private struct ScheduleCurrentTimeIndicator: View {
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)

            RoundedRectangle(cornerRadius: 1)
                .fill(Color.red)
                .frame(maxWidth: .infinity)
                .frame(height: 2)
        }
        .frame(maxWidth: .infinity, minHeight: 8, maxHeight: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("当前时间")
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
