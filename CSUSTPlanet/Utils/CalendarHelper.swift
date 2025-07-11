//
//  CalendarHelper.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import EventKit
import Foundation

class CalendarHelper {
    private let eventStore = EKEventStore()

    func requestAccess() async throws -> Bool {
        return try await eventStore.requestFullAccessToEvents()
    }

    func eventExists(title: String, startDate: Date, endDate: Date) async throws -> Bool {
        let granted = try await requestAccess()
        guard granted else {
            throw CalendarHelperError.permissionDenied
        }

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)

        let events = eventStore.events(matching: predicate)
        return events.contains { $0.title == title && $0.startDate == startDate && $0.endDate == endDate }
    }

    func addEvent(title: String, startDate: Date, endDate: Date, notes: String? = nil, location: String? = nil) async throws {
        let granted = try await requestAccess()
        guard granted else {
            throw CalendarHelperError.permissionDenied
        }

        if try await eventExists(title: title, startDate: startDate, endDate: endDate) {
            return
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.location = location
        event.calendar = eventStore.defaultCalendarForNewEvents

        try eventStore.save(event, span: .thisEvent)
    }

    enum CalendarHelperError: Error, LocalizedError {
        case permissionDenied

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "日历权限被拒绝，请在设置中开启权限。"
            }
        }
    }
}
