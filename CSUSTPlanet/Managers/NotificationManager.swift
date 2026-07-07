//
//  NotificationManager.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/15.
//

import Combine
import Foundation
import SwiftUI
import UserNotifications

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum NotificationPermissionStatus: String {
    case authorized = "已开启"
    case denied = "已关闭"
    case requestable = "未设置"
}

struct LocalNotificationDraft {
    let identifier: String
    let threadIdentifier: String
    let title: String
    let subtitle: String
    let body: String
    let triggerDate: Date
    let userInfo: [AnyHashable: Any]
}

@MainActor
@Observable
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private var cancellables = Set<AnyCancellable>()

    private var permissionStatusSubject = CurrentValueSubject<NotificationPermissionStatus?, Never>(nil)
    private(set) var permissionStatus: NotificationPermissionStatus? {
        didSet {
            permissionStatusSubject.send(permissionStatus)
        }
    }
    var permissionStatusPublisher: AnyPublisher<NotificationPermissionStatus?, Never> {
        permissionStatusSubject.eraseToAnyPublisher()
    }

    private init() {
        startObservingLifecycle()

        Task {
            await updatePermissionStatus()
        }
    }

    private func startObservingLifecycle() {
        LifecycleManager.shared.events
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .didBecomeActive:
                    Task {
                        await self.updatePermissionStatus()
                    }
                case .didBecomeInactive, .didEnterBackground:
                    break
                }
            }
            .store(in: &cancellables)
    }

    func requestPermission() async throws -> Bool {
        let isGranted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        await updatePermissionStatus()
        return isGranted
    }

    func updatePermissionStatus() async {
        let settings = await center.notificationSettings()

        let status: NotificationPermissionStatus
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            status = .authorized
        case .denied:
            status = .denied
            center.removeAllPendingNotificationRequests()
        case .notDetermined:
            status = .requestable
        @unknown default:
            status = .requestable
        }

        withAnimation { permissionStatus = status }
    }

    func openAppNotificationSettings() {
        #if os(iOS)
        if let url = URL(string: PlatformApplication.openNotificationSettingsURLString),
            PlatformApplication.shared.canOpenURL(url)
        {
            PlatformApplication.shared.open(url)
        }
        #elseif os(macOS)
        let settingsURL = "x-apple.systempreferences:com.apple.Notifications-Settings.extension"
        if let url = URL(string: settingsURL) {
            NSWorkspace.shared.open(url)
        }
        #endif
    }
}

// MARK: - Local Notification

extension NotificationManager {
    func syncLocalNotifications(prefix: String, drafts: [LocalNotificationDraft]) async throws {
        let pendingRequests = await center.pendingNotificationRequests()
        let pendingIdsToClear =
            pendingRequests
            .map(\.identifier)
            .filter { $0.hasPrefix(prefix) }

        if !pendingIdsToClear.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: pendingIdsToClear)
        }

        for draft in drafts where draft.triggerDate > .now {
            let content = UNMutableNotificationContent()
            content.title = draft.title
            content.subtitle = draft.subtitle
            content.body = draft.body
            content.sound = .default
            content.threadIdentifier = draft.threadIdentifier
            content.userInfo = draft.userInfo

            let dateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: draft.triggerDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: draft.identifier, content: content, trigger: trigger)
            try await center.add(request)
        }
    }

    func clearLocalNotifications(prefix: String) async {
        let pendingRequests = await center.pendingNotificationRequests()
        let pendingIdentifiers =
            pendingRequests
            .map(\.identifier)
            .filter { $0.hasPrefix(prefix) }
        if !pendingIdentifiers.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: pendingIdentifiers)
        }
    }
}

extension Data {
    fileprivate var hexString: String {
        self.map { String(format: "%02.2hhx", $0) }.joined()
    }
}
