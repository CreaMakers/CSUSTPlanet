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
    @State private var visibleSectionID: ScheduleTimelineSectionID?
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
                ForEach(timelineSections) { section in
                    Group {
                        switch section {
                        case .day(let daySection):
                            ScheduleDaySectionView(
                                section: daySection,
                                referenceDate: referenceDate,
                                currentIndicatorPlacement: currentIndicatorPlacement,
                                onSelectEvent: { selectedEvent = $0 }
                            )
                        case .empty(let emptySection):
                            ScheduleEmptySectionView(
                                section: emptySection,
                                referenceDate: referenceDate,
                                showsIndicator: showsIndicator(in: emptySection)
                            )
                        }
                    }
                    .id(section.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $visibleSectionID, anchor: .top)
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
        .onChange(of: timelineSectionIDs, initial: true) { _, _ in
            guard
                !hasPerformedInitialScroll,
                let todaySectionID = timelineSections.first(where: { $0.contains(todayID) })?.id
            else {
                return
            }

            hasPerformedInitialScroll = true
            visibleSectionID = todaySectionID
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

    private var timelineSections: [ScheduleTimelineSection] {
        var groupedEvents: [Date: [ScheduleEvent]] = [:]

        for event in sortedEvents {
            groupedEvents[ScheduleDateUtil.eventDay(for: event), default: []].append(event)
        }

        let occupiedDays = groupedEvents.keys.sorted()

        guard let firstOccupiedDay = occupiedDays.first, let lastOccupiedDay = occupiedDays.last else {
            return [.empty(ScheduleEmptySection(startDate: todayID, endDate: todayID))]
        }

        var sections: [ScheduleTimelineSection] = []

        if todayID < firstOccupiedDay {
            sections.append(
                .empty(
                    ScheduleEmptySection(
                        startDate: todayID,
                        endDate: dayBefore(firstOccupiedDay)
                    )
                )
            )
        }

        for (index, day) in occupiedDays.enumerated() {
            sections.append(
                .day(
                    ScheduleDaySection(
                        id: day,
                        events: groupedEvents[day, default: []]
                    )
                )
            )

            guard index + 1 < occupiedDays.count else {
                continue
            }

            let nextDay = occupiedDays[index + 1]

            let emptyStartDate = dayAfter(day)
            let emptyEndDate = dayBefore(nextDay)
            if emptyStartDate <= emptyEndDate {
                sections.append(
                    .empty(
                        ScheduleEmptySection(
                            startDate: emptyStartDate,
                            endDate: emptyEndDate
                        )
                    )
                )
            }
        }

        if lastOccupiedDay < todayID {
            sections.append(
                .empty(
                    ScheduleEmptySection(
                        startDate: dayAfter(lastOccupiedDay),
                        endDate: todayID
                    )
                )
            )
        }

        return sections
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

    private var currentIndicatorPlacement: ScheduleCurrentIndicatorPlacement? {
        if let currentEvent = sortedEvents.first(where: isCurrentEvent(_:)) {
            return .beforeEvent(currentEvent.id)
        }

        let todayEvents = sortedEvents.filter {
            ScheduleDateUtil.isSameDay(ScheduleDateUtil.eventDay(for: $0), todayID)
        }

        if let nextTodayEvent = todayEvents.first(where: { $0.timing.anchorDate >= referenceDate }) {
            return .beforeEvent(nextTodayEvent.id)
        }

        if !todayEvents.isEmpty {
            return .afterDay(todayID)
        }

        if let emptySection = timelineSections.first(where: { $0.contains(todayID) }) {
            return .inEmptySection(emptySection.id)
        }

        return nil
    }

    private func showsIndicator(in section: ScheduleEmptySection) -> Bool {
        guard case .some(.inEmptySection(let sectionID)) = currentIndicatorPlacement else {
            return false
        }

        return sectionID == section.id
    }

    private var timelineSectionIDs: [ScheduleTimelineSectionID] {
        timelineSections.map(\.id)
    }

    private var todayID: Date {
        ScheduleDateUtil.startOfDay(for: referenceDate)
    }

    private var activeDayID: Date {
        guard
            let visibleSectionID,
            let visibleSection = timelineSections.first(where: { $0.id == visibleSectionID })
        else {
            return todayID
        }

        switch visibleSection {
        case .day(let section):
            return section.id
        case .empty(let section):
            return section.contains(todayID) ? todayID : section.startDate
        }
    }

    private func scrollToNearestDate(_ date: Date) {
        guard let targetSectionID = timelineSections.first(where: { $0.contains(date) })?.id else {
            return
        }

        withAnimation {
            visibleSectionID = targetSectionID
        }
    }

    private func dayBefore(_ date: Date) -> Date {
        ScheduleDateUtil.calendar.date(byAdding: .day, value: -1, to: date)!
    }

    private func dayAfter(_ date: Date) -> Date {
        ScheduleDateUtil.calendar.date(byAdding: .day, value: 1, to: date)!
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

private enum ScheduleTimelineSectionID: Hashable {
    case day(Date)
    case empty(startDate: Date, endDate: Date)
}

private enum ScheduleTimelineSection: Identifiable {
    case day(ScheduleDaySection)
    case empty(ScheduleEmptySection)

    var id: ScheduleTimelineSectionID {
        switch self {
        case .day(let section):
            return .day(section.id)
        case .empty(let section):
            return section.id
        }
    }

    func contains(_ date: Date) -> Bool {
        switch self {
        case .day(let section):
            return ScheduleDateUtil.isSameDay(section.id, date)
        case .empty(let section):
            return section.contains(date)
        }
    }
}

private struct ScheduleDaySection {
    let id: Date
    let events: [ScheduleEvent]
}

private struct ScheduleEmptySection {
    let startDate: Date
    let endDate: Date

    var id: ScheduleTimelineSectionID {
        .empty(startDate: startDate, endDate: endDate)
    }

    var dayCount: Int {
        let components = ScheduleDateUtil.calendar.dateComponents(
            [.day],
            from: startDate,
            to: endDate
        )
        return (components.day ?? 0) + 1
    }

    func contains(_ date: Date) -> Bool {
        let day = ScheduleDateUtil.startOfDay(for: date)
        return startDate <= day && day <= endDate
    }
}

private enum ScheduleCurrentIndicatorPlacement: Equatable {
    case beforeEvent(String)
    case afterDay(Date)
    case inEmptySection(ScheduleTimelineSectionID)
}

private struct ScheduleDaySectionView: View {
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

private struct ScheduleEmptySectionView: View {
    let section: ScheduleEmptySection
    let referenceDate: Date
    let showsIndicator: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .font(.headline.weight(.semibold))

                Spacer(minLength: 8)

                Text("连续 \(section.dayCount) 天")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
