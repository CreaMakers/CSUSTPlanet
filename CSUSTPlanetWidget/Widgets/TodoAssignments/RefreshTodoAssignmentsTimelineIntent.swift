//
//  RefreshTodoAssignmentsTimelineIntent.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zachary Liu on 2026/3/27.
//

import AppIntents
import CSUSTKit
import OSLog
import WidgetKit

struct RefreshTodoAssignmentsTimelineIntent: AppIntent {
    static var title: LocalizedStringResource = "刷新待提交作业时间线"
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        TrackHelper.shared.event(category: "Widget", action: "Refresh", name: "TodoAssignmentsWidget")
        await Self.update()
        return .result()
    }

    static func update() async {
        do {
            let mode: ConnectionMode = MMKVHelper.GlobalManager.isWebVPNModeEnabled ? .webVpn : .direct
            let session = CookieHelper.shared.session

            let ssoHelper = SSOHelper(mode: mode, session: session)
            let moocHelper = MoocHelper(mode: mode, session: session)

            if await !moocHelper.isLoggedIn() {
                if await ssoHelper.isLoggedIn() {
                    try await ssoHelper.loginToMooc()
                    CookieHelper.shared.save()
                } else {
                    guard let username = KeychainUtil.ssoUsername, let password = KeychainUtil.ssoPassword else {
                        return
                    }
                    let loginForm = try await ssoHelper.getLoginForm()
                    try await ssoHelper.login(loginForm: loginForm, username: username, password: password, captcha: nil)

                    try await ssoHelper.loginToMooc()
                    CookieHelper.shared.save()
                }
            }

            let courses = try await moocHelper.getCoursesWithPendingAssignments()
            var groups: [TodoAssignmentsData] = []

            for course in courses {
                let assignments = try await moocHelper.getCourseAssignments(course: course)
                groups.append(.init(course: course, assignments: assignments))
            }

            MMKVHelper.TodoAssignments.cache = Cached(cachedAt: .now, value: groups)
        } catch {
            return
        }
    }
}
