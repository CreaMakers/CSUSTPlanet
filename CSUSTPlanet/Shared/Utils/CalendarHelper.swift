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

    func getOrCreateCalendar(named: String) async throws -> EKCalendar {
        if let existingCalendar = eventStore.calendars(for: .event).first(where: { $0.title == named }) {
            return existingCalendar
        }

        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = named

        if let iCloudSource = eventStore.sources.first(where: { $0.sourceType == .calDAV && $0.title == "iCloud" }) {
            newCalendar.source = iCloudSource
        } else if let defaultSource = eventStore.sources.first {
            newCalendar.source = defaultSource
        } else {
            throw CalendarHelperError.noAvailableSource
        }

        try eventStore.saveCalendar(newCalendar, commit: true)
        return newCalendar
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

    func addEvent(title: String, startDate: Date, endDate: Date, notes: String? = nil, location: String? = nil, calendar: EKCalendar? = nil) async throws {
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
        event.calendar = calendar ?? eventStore.defaultCalendarForNewEvents

        try eventStore.save(event, span: .thisEvent)
    }

    enum CalendarHelperError: Error, LocalizedError {
        case permissionDenied
        case noAvailableSource

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "日历权限被拒绝，请在设置中开启权限。"
            case .noAvailableSource:
                return "未找到可用的日历账户，请前往系统设置添加 iCloud 或其他日历账户。"
            }
        }
    }
}
