//
//  CalendarUtil.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import CSUSTKit
import EventKit
import Foundation

// MARK: - Error

enum CalendarUtilError: Error, LocalizedError {
    case eventPermissionDenied
    case reminderPermissionDenied
    case noAvailableSource
    case fetchRemindersFailed

    var errorDescription: String? {
        switch self {
        case .eventPermissionDenied:
            return "日历权限被拒绝，请在设置中开启权限。"
        case .reminderPermissionDenied:
            return "提醒事项权限被拒绝，请在设置中开启权限。"
        case .noAvailableSource:
            return "未找到可用的日历账户，请前往系统设置添加 iCloud 或其他日历账户。"
        case .fetchRemindersFailed:
            return "获取提醒事项失败。"
        }
    }
}

// MARK: - CalendarUtil

enum CalendarUtil {
    private static let eventStore = EKEventStore()
    private static let calendarTitlePrefix = "云岭星球 - "
}

struct CalendarEventDraft {
    let title: String
    let startDate: Date
    let endDate: Date
    let notes: String?
    let location: String?
    let timeZone: TimeZone
    let alarmRelativeOffsets: [TimeInterval]
}

// MARK: - Permission

extension CalendarUtil {
    static func requestEventAccess() async throws -> Bool {
        return try await eventStore.requestFullAccessToEvents()
    }

    static func requestReminderAccess() async throws -> Bool {
        return try await eventStore.requestFullAccessToReminders()
    }
}

// MARK: - Event

extension CalendarUtil {
    static func getOrCreateEventCalendar(suffix: String) async throws -> EKCalendar {
        let title = calendarTitlePrefix + suffix
        guard try await requestEventAccess() else { throw CalendarUtilError.eventPermissionDenied }

        if let existingCalendar = eventStore.calendars(for: .event).first(where: { $0.title == title }) {
            return existingCalendar
        }

        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = title

        if let defaultListSource = eventStore.defaultCalendarForNewEvents?.source {
            newCalendar.source = defaultListSource
        } else if let iCloudSource = eventStore.sources.first(where: { $0.sourceType == .calDAV && $0.title.contains("iCloud") }) {
            newCalendar.source = iCloudSource
        } else if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
            newCalendar.source = localSource
        } else {
            throw CalendarUtilError.noAvailableSource
        }

        try eventStore.saveCalendar(newCalendar, commit: true)
        return newCalendar
    }

    static func addEvent(
        calendar: EKCalendar,
        title: String,
        startDate: Date,
        endDate: Date,
        notes: String? = nil,
        location: String? = nil,
        alarms: [EKAlarm]? = nil
    ) async throws {
        guard try await requestEventAccess() else { throw CalendarUtilError.eventPermissionDenied }
        guard try await !eventExists(calendar: calendar, title: title, startDate: startDate, endDate: endDate) else { return }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.location = location
        event.calendar = calendar

        if let alarms = alarms {
            for alarm in alarms {
                event.addAlarm(alarm)
            }
        }

        try eventStore.save(event, span: .thisEvent)
    }

    static private func eventExists(calendar: EKCalendar, title: String, startDate: Date, endDate: Date) async throws -> Bool {
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])
        let events = eventStore.events(matching: predicate)
        return events.contains { $0.title == title && $0.startDate == startDate && $0.endDate == endDate }
    }

    /// 原子替换指定时间范围内的全部事件
    static func replaceEvents(
        calendar: EKCalendar,
        from startDate: Date,
        to endDate: Date,
        with drafts: [CalendarEventDraft]
    ) async throws {
        guard try await requestEventAccess() else { throw CalendarUtilError.eventPermissionDenied }

        do {
            let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])
            for event in eventStore.events(matching: predicate) {
                try eventStore.remove(event, span: .thisEvent, commit: false)
            }

            for draft in drafts {
                let event = EKEvent(eventStore: eventStore)
                event.title = draft.title
                event.startDate = draft.startDate
                event.endDate = draft.endDate
                event.notes = draft.notes
                event.location = draft.location
                event.timeZone = draft.timeZone
                event.calendar = calendar

                for offset in draft.alarmRelativeOffsets {
                    event.addAlarm(EKAlarm(relativeOffset: offset))
                }

                try eventStore.save(event, span: .thisEvent, commit: false)
            }

            try eventStore.commit()
        } catch {
            eventStore.reset()
            throw error
        }
    }
}

// MARK: - Reminder

extension CalendarUtil {
    static func getOrCreateReminderCalendar(suffix: String) async throws -> EKCalendar {
        let title = calendarTitlePrefix + suffix
        guard try await requestReminderAccess() else { throw CalendarUtilError.reminderPermissionDenied }

        if let existingCalendar = eventStore.calendars(for: .reminder).first(where: { $0.title == title }) {
            return existingCalendar
        }

        let newCalendar = EKCalendar(for: .reminder, eventStore: eventStore)
        newCalendar.title = title

        if let defaultListSource = eventStore.defaultCalendarForNewReminders()?.source {
            newCalendar.source = defaultListSource
        } else if let iCloudSource = eventStore.sources.first(where: { $0.sourceType == .calDAV && $0.title.contains("iCloud") }) {
            newCalendar.source = iCloudSource
        } else if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
            newCalendar.source = localSource
        } else {
            throw CalendarUtilError.noAvailableSource
        }

        try eventStore.saveCalendar(newCalendar, commit: true)
        return newCalendar
    }

    static func addReminder(
        calendar: EKCalendar,
        title: String,
        dueDate: Date?,
        notes: String? = nil
    ) async throws {
        guard try await requestReminderAccess() else { throw CalendarUtilError.reminderPermissionDenied }
        guard try await !reminderExists(calendar: calendar, title: title, dueDate: dueDate) else { return }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.notes = notes
        reminder.calendar = calendar

        if let dueDate = dueDate {
            let dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
            reminder.dueDateComponents = dueDateComponents
        }

        try eventStore.save(reminder, commit: true)
    }

    static private func reminderExists(calendar: EKCalendar, title: String, dueDate: Date?) async throws -> Bool {
        let reminders = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[EKReminder], Error>) in
            let predicate = eventStore.predicateForReminders(in: [calendar])
            eventStore.fetchReminders(matching: predicate) { fetchedReminders in
                if let reminders = fetchedReminders {
                    continuation.resume(returning: reminders)
                } else {
                    continuation.resume(throwing: CalendarUtilError.fetchRemindersFailed)
                }
            }
        }

        return reminders.contains { reminder in
            guard reminder.title == title else {
                return false
            }

            let calendar = Calendar.current
            let existingDueDate: Date? = reminder.dueDateComponents.flatMap { calendar.date(from: $0) }

            if let dueDate = dueDate, let existingDueDate = existingDueDate {
                return calendar.compare(dueDate, to: existingDueDate, toGranularity: .minute) == .orderedSame
            } else {
                return dueDate == nil && existingDueDate == nil
            }
        }
    }
}
