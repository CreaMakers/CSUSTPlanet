//
//  TodoAssignmentsView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/20.
//

import CSUSTKit
import SwiftUI

struct TodoAssignmentsView: View {
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif

    @State private var todoAssignmentsData: Cached<[TodoAssignmentsData]>?
    @State private var submittableAssignmentsCount = 0
    @State private var assignmentsReferenceDate = Date.now
    @State private var expandedCourseIDs: Set<String> = []
    @State private var showAllAssignmentsCourseIDs: Set<String> = []

    @State private var selectedCourseID: String?
    @State private var isCoursePagePresented = false

    @State private var isLoadingAssignments = false
    @State private var errorToast: ToastState = .errorTitle

    @State private var isNotificationDeniedAlertPresented = false
    @State private var isNotificationSettingsPresented = false

    @State private var isInitial = true

    var body: some View {
        TodoAssignmentsContent(
            courseGroups: todoAssignmentsData?.value,
            referenceDate: assignmentsReferenceDate,
            submittableAssignmentsCount: submittableAssignmentsCount,
            isLoadingAssignments: isLoadingAssignments,
            expandedCourseIDs: $expandedCourseIDs,
            showAllAssignmentsCourseIDs: $showAllAssignmentsCourseIDs,
            errorToast: $errorToast,
            selectedCourseID: $selectedCourseID,
            isCoursePagePresented: $isCoursePagePresented,
            isNotificationSettingsPresented: $isNotificationSettingsPresented,
            isNotificationDeniedAlertPresented: $isNotificationDeniedAlertPresented,
            onRefreshAssignments: loadTodoAssignments,
            onSaveNotificationSettings: saveNotificationSettings,
            onOpenCoursePage: openCoursePage,
            onOpenNotificationSettings: openNotificationSettings
        )
        .onReceive(MMKVHelper.TodoAssignments.$cache.dropFirst().receive(on: RunLoop.main)) { data in
            applyData(data)
        }
        .task {
            guard isInitial else {
                return
            }
            isInitial = false
            applyData(MMKVHelper.TodoAssignments.cache)
            await syncTodoNotificationsSilently()
            await loadTodoAssignments()
        }
    }

    // MARK: - Methods

    private func loadTodoAssignments() async {
        guard !isLoadingAssignments else { return }
        isLoadingAssignments = true
        defer { isLoadingAssignments = false }

        do {
            let courses = try await AuthManager.shared.withAuthRetry(system: .mooc) {
                try await AuthManager.shared.moocHelper.getCoursesWithPendingAssignments()
            }
            var newGroups: [TodoAssignmentsData] = []

            for course in courses {
                let assignments = try await AuthManager.shared.withAuthRetry(system: .mooc) {
                    try await AuthManager.shared.moocHelper.getCourseAssignments(course: course)
                }
                newGroups.append(.init(course: course, assignments: assignments))
            }

            let data = Cached(cachedAt: .now, value: newGroups)
            MMKVHelper.TodoAssignments.cache = data
            WidgetTimelineRefreshHelper.reloadTodoAssignments()

            let drafts = TodoAssignmentsNotificationHelper.buildLocalNotificationDrafts(
                groups: data.value,
                reminderOffsetHour: MMKVHelper.TodoAssignments.notificationOffsetHour,
                reminderOffsetMinute: MMKVHelper.TodoAssignments.notificationOffsetMinute
            )
            await TodoAssignmentsNotificationHelper.syncTodoNotificationsSilently(
                isNotificationEnabled: MMKVHelper.TodoAssignments.isNotificationEnabled,
                drafts: drafts,
                onPermissionDenied: {
                    MMKVHelper.TodoAssignments.isNotificationEnabled = false
                }
            )
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func applyData(_ data: Cached<[TodoAssignmentsData]>?) {
        todoAssignmentsData = data
        assignmentsReferenceDate = .now

        guard let data else {
            submittableAssignmentsCount = 0
            expandedCourseIDs = []
            showAllAssignmentsCourseIDs = []
            return
        }

        let existingCourseIDs = Set(data.value.map(\.course.id))
        submittableAssignmentsCount = data.value.reduce(0) { count, group in
            count + group.assignments.filter { $0.isSubmittable(referenceDate: assignmentsReferenceDate) }.count
        }
        expandedCourseIDs = existingCourseIDs
        showAllAssignmentsCourseIDs = showAllAssignmentsCourseIDs.intersection(existingCourseIDs)
    }

    private func openCoursePage(courseID: String) {
        #if os(macOS)
        openWindow(id: TodoAssignmentsCoursePageScene.windowID, value: courseID)
        #else
        selectedCourseID = courseID
        isCoursePagePresented = true
        #endif
    }

    private func openNotificationSettings() {
        NotificationManager.shared.openAppNotificationSettings()
        isNotificationDeniedAlertPresented = false
    }

    private func saveNotificationSettings(enabled: Bool, hour: Int, minute: Int) async {
        let wasNotificationEnabled = MMKVHelper.TodoAssignments.isNotificationEnabled
        MMKVHelper.TodoAssignments.notificationOffsetHour = hour
        MMKVHelper.TodoAssignments.notificationOffsetMinute = minute

        if enabled == wasNotificationEnabled {
            if enabled {
                await syncTodoNotificationsInteractively()
            } else {
                await NotificationManager.shared.clearLocalNotifications(prefix: TodoAssignmentsNotificationHelper.notificationPrefix)
            }
            return
        }

        await updateTodoNotificationEnabled(enabled)
    }

    private func updateTodoNotificationEnabled(_ enabled: Bool) async {
        if !enabled {
            MMKVHelper.TodoAssignments.isNotificationEnabled = false
            await NotificationManager.shared.clearLocalNotifications(prefix: TodoAssignmentsNotificationHelper.notificationPrefix)
            return
        }

        await NotificationManager.shared.updatePermissionStatus()
        let permissionStatus = NotificationManager.shared.permissionStatus ?? .requestable

        do {
            switch permissionStatus {
            case .authorized:
                MMKVHelper.TodoAssignments.isNotificationEnabled = true
                await syncTodoNotificationsInteractively()
            case .denied:
                MMKVHelper.TodoAssignments.isNotificationEnabled = false
                isNotificationDeniedAlertPresented = true
            case .requestable:
                guard try await NotificationManager.shared.requestPermission() else {
                    MMKVHelper.TodoAssignments.isNotificationEnabled = false
                    isNotificationDeniedAlertPresented = true
                    return
                }
                MMKVHelper.TodoAssignments.isNotificationEnabled = true
                await syncTodoNotificationsInteractively()
            }
        } catch {
            MMKVHelper.TodoAssignments.isNotificationEnabled = false
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func syncTodoNotificationsSilently() async {
        let drafts = TodoAssignmentsNotificationHelper.buildLocalNotificationDrafts(
            groups: todoAssignmentsData?.value ?? [],
            reminderOffsetHour: MMKVHelper.TodoAssignments.notificationOffsetHour,
            reminderOffsetMinute: MMKVHelper.TodoAssignments.notificationOffsetMinute
        )

        await TodoAssignmentsNotificationHelper.syncTodoNotificationsSilently(
            isNotificationEnabled: MMKVHelper.TodoAssignments.isNotificationEnabled,
            drafts: drafts,
            onPermissionDenied: {
                MMKVHelper.TodoAssignments.isNotificationEnabled = false
            }
        )
    }

    private func syncTodoNotificationsInteractively() async {
        do {
            await NotificationManager.shared.updatePermissionStatus()
            let permissionStatus = NotificationManager.shared.permissionStatus ?? .requestable

            if permissionStatus == .denied {
                MMKVHelper.TodoAssignments.isNotificationEnabled = false
                isNotificationDeniedAlertPresented = true
                return
            }

            guard permissionStatus == .authorized else {
                errorToast.show(message: "通知权限未开启")
                return
            }

            guard MMKVHelper.TodoAssignments.isNotificationEnabled else {
                await NotificationManager.shared.clearLocalNotifications(prefix: TodoAssignmentsNotificationHelper.notificationPrefix)
                return
            }

            let drafts = TodoAssignmentsNotificationHelper.buildLocalNotificationDrafts(
                groups: todoAssignmentsData?.value ?? [],
                reminderOffsetHour: MMKVHelper.TodoAssignments.notificationOffsetHour,
                reminderOffsetMinute: MMKVHelper.TodoAssignments.notificationOffsetMinute
            )
            try await NotificationManager.shared.syncLocalNotifications(prefix: TodoAssignmentsNotificationHelper.notificationPrefix, drafts: drafts)
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}

@MainActor
enum TodoAssignmentsNotificationHelper {
    static let notificationPrefix = "todo-assignments."
    private static let notificationThread = "todo-assignments.thread"

    static func syncTodoNotificationsSilently(
        isNotificationEnabled: Bool,
        drafts: [LocalNotificationDraft],
        onPermissionDenied: () -> Void = {}
    ) async {
        do {
            await NotificationManager.shared.updatePermissionStatus()
            let permissionStatus = NotificationManager.shared.permissionStatus ?? .requestable

            if permissionStatus == .denied {
                if isNotificationEnabled {
                    onPermissionDenied()
                }
                return
            }

            guard isNotificationEnabled else {
                await NotificationManager.shared.clearLocalNotifications(prefix: notificationPrefix)
                return
            }

            guard permissionStatus == .authorized else { return }

            try await NotificationManager.shared.syncLocalNotifications(prefix: notificationPrefix, drafts: drafts)
        } catch {}
    }

    static func buildLocalNotificationDrafts(
        groups: [TodoAssignmentsData],
        reminderOffsetHour: Int,
        reminderOffsetMinute: Int
    ) -> [LocalNotificationDraft] {
        let reminderOffsetSeconds = reminderOffsetSeconds(
            hour: reminderOffsetHour,
            minute: reminderOffsetMinute
        )
        let now = Date.now

        return groups.flatMap { group in
            group.assignments.compactMap { assignment in
                guard assignment.canSubmit else { return nil }
                guard !assignment.submitStatus else { return nil }
                guard assignment.deadline > now else { return nil }

                let triggerDate = assignment.deadline.addingTimeInterval(-reminderOffsetSeconds)
                guard triggerDate > now else { return nil }

                let identifier = "\(notificationPrefix)\(group.course.id).\(assignment.id)"

                return LocalNotificationDraft(
                    identifier: identifier,
                    threadIdentifier: notificationThread,
                    title: "作业截止提醒",
                    subtitle: group.course.name,
                    body: "\(assignment.title) 将在 \(assignment.deadline.formatted(.dateTime.month().day().hour().minute())) 截止",
                    triggerDate: triggerDate,
                    userInfo: [:]
                )
            }
        }
    }

    private static func reminderOffsetSeconds(hour: Int, minute: Int) -> TimeInterval {
        let clampedHour = min(max(hour, 0), 72)
        let clampedMinute = min(max(minute, 0), 59)
        return TimeInterval(clampedHour * 3600 + clampedMinute * 60)
    }
}

extension MMKVHelper.TodoAssignments {
    @MMKVStorage(key: "TodoAssignments.isNotificationEnabled", defaultValue: false)
    static var isNotificationEnabled: Bool

    @MMKVStorage(key: "TodoAssignments.notificationOffsetHour", defaultValue: 2)
    static var notificationOffsetHour: Int

    @MMKVStorage(key: "TodoAssignments.notificationOffsetMinute", defaultValue: 0)
    static var notificationOffsetMinute: Int
}
