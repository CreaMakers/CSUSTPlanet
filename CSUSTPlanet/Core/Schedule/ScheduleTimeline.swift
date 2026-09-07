//
//  ScheduleTimeline.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/9/7.
//

import Foundation

struct ScheduleTimelineData {
    let referenceDate: Date
    let sections: [ScheduleTimelineSection]
    let eventDates: Set<Date>
    let currentIndicatorPlacement: ScheduleCurrentIndicatorPlacement?
}
enum ScheduleTimelineSection: Identifiable {
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

struct ScheduleDaySection {
    let id: Date
    let events: [ScheduleEvent]
}

struct ScheduleEmptySection {
    let startDate: Date
    let endDate: Date

    var id: ScheduleTimelineSectionID {
        .empty(startDate: startDate, endDate: endDate)
    }

    var dayCount: Int {
        let components = ScheduleDateUtil.calendar.dateComponents([.day], from: startDate, to: endDate)
        return (components.day ?? 0) + 1
    }

    func contains(_ date: Date) -> Bool {
        let day = ScheduleDateUtil.startOfDay(for: date)
        return startDate <= day && day <= endDate
    }
}

enum ScheduleTimelineSectionID: Hashable {
    case day(Date)
    case empty(startDate: Date, endDate: Date)
}

enum ScheduleCurrentIndicatorPlacement: Equatable {
    case beforeEvent(String)
    case afterDay(Date)
    case inEmptySection(ScheduleTimelineSectionID)
}

enum ScheduleTimelineBuilder {
    static func makeData(events: [ScheduleEvent], referenceDate: Date) -> ScheduleTimelineData {
        let sortedEvents = events.sorted(by: sortEvents)
        let sections = makeSections(from: sortedEvents, referenceDate: referenceDate)

        return ScheduleTimelineData(
            referenceDate: referenceDate,
            sections: sections,
            eventDates: Set(events.map(ScheduleDateUtil.eventDay(for:))),
            currentIndicatorPlacement: makeCurrentIndicatorPlacement(
                sortedEvents: sortedEvents,
                sections: sections,
                referenceDate: referenceDate
            )
        )
    }

    private static func makeSections(from sortedEvents: [ScheduleEvent], referenceDate: Date) -> [ScheduleTimelineSection] {
        var groupedEvents: [Date: [ScheduleEvent]] = [:]

        for event in sortedEvents {
            groupedEvents[ScheduleDateUtil.eventDay(for: event), default: []].append(event)
        }

        let occupiedDays = groupedEvents.keys.sorted()
        let todayID = ScheduleDateUtil.startOfDay(for: referenceDate)

        guard let firstOccupiedDay = occupiedDays.first, let lastOccupiedDay = occupiedDays.last else {
            return [.empty(ScheduleEmptySection(startDate: todayID, endDate: todayID))]
        }

        var sections: [ScheduleTimelineSection] = []

        if todayID < firstOccupiedDay {
            sections.append(.empty(ScheduleEmptySection(startDate: todayID, endDate: dayBefore(firstOccupiedDay))))
        }

        for (index, day) in occupiedDays.enumerated() {
            sections.append(.day(ScheduleDaySection(id: day, events: groupedEvents[day, default: []])))

            guard index + 1 < occupiedDays.count else {
                continue
            }

            let nextDay = occupiedDays[index + 1]
            let emptyStartDate = dayAfter(day)
            let emptyEndDate = dayBefore(nextDay)

            if emptyStartDate <= emptyEndDate {
                sections.append(.empty(ScheduleEmptySection(startDate: emptyStartDate, endDate: emptyEndDate)))
            }
        }

        if lastOccupiedDay < todayID {
            sections.append(
                .empty(ScheduleEmptySection(startDate: dayAfter(lastOccupiedDay), endDate: todayID))
            )
        }

        return sections
    }

    private static func makeCurrentIndicatorPlacement(sortedEvents: [ScheduleEvent], sections: [ScheduleTimelineSection], referenceDate: Date) -> ScheduleCurrentIndicatorPlacement? {
        if let currentEvent = sortedEvents.first(where: { event in
            guard case .interval(let start, let end) = event.timing else {
                return false
            }
            return start <= referenceDate && referenceDate < end
        }) {
            return .beforeEvent(currentEvent.id)
        }

        let todayID = ScheduleDateUtil.startOfDay(for: referenceDate)
        let todayEvents = sortedEvents.filter {
            ScheduleDateUtil.isSameDay(ScheduleDateUtil.eventDay(for: $0), todayID)
        }

        if let nextTodayEvent = todayEvents.first(where: { $0.timing.anchorDate >= referenceDate }) {
            return .beforeEvent(nextTodayEvent.id)
        }

        if !todayEvents.isEmpty {
            return .afterDay(todayID)
        }

        if let emptySection = sections.first(where: { $0.contains(todayID) }) {
            return .inEmptySection(emptySection.id)
        }

        return nil
    }

    private static func sortEvents(_ lhs: ScheduleEvent, _ rhs: ScheduleEvent) -> Bool {
        if lhs.timing.anchorDate != rhs.timing.anchorDate {
            return lhs.timing.anchorDate < rhs.timing.anchorDate
        }

        if lhs.kind.presentationSortPriority != rhs.kind.presentationSortPriority {
            return lhs.kind.presentationSortPriority < rhs.kind.presentationSortPriority
        }

        return lhs.id < rhs.id
    }

    private static func dayBefore(_ date: Date) -> Date {
        ScheduleDateUtil.calendar.date(byAdding: .day, value: -1, to: date)!
    }

    private static func dayAfter(_ date: Date) -> Date {
        ScheduleDateUtil.calendar.date(byAdding: .day, value: 1, to: date)!
    }
}
