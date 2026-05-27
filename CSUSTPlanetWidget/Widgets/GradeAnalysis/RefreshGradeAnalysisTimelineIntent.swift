//
//  RefreshGradeAnalysisTimelineIntent.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/7/22.
//

import AppIntents
import CSUSTKit
import OSLog
import WidgetKit

struct RefreshGradeAnalysisTimelineIntent: AppIntent {
    static var title: LocalizedStringResource = "刷新成绩分析时间线"
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        TrackHelper.shared.event(category: "Widget", action: "Refresh", name: "GradeAnalysisWidget")
        await Self.update()
        return .result()
    }

    static func update() async {
        do {
            let mode: ConnectionMode = MMKVHelper.GlobalManager.isWebVPNModeEnabled ? .webVpn : .direct
            let session = CookieHelper.shared.session

            let ssoHelper = SSOHelper(mode: mode, session: session)
            let eduHelper = EduHelper(mode: mode, session: session)

            if await !eduHelper.isLoggedIn() {
                if await ssoHelper.isLoggedIn() {
                    try await ssoHelper.loginToEducation()
                    CookieHelper.shared.save()
                } else {
                    guard let username = KeychainUtil.ssoUsername, let password = KeychainUtil.ssoPassword else {
                        return
                    }
                    let loginForm = try await ssoHelper.getLoginForm()
                    try await ssoHelper.login(loginForm: loginForm, username: username, password: password, captcha: nil)

                    try await ssoHelper.loginToEducation()
                    CookieHelper.shared.save()
                }
            }

            let courseGrades = try await eduHelper.courseService.getCourseGrades()
            MMKVHelper.CourseGrades.cache = Cached<[EduHelper.CourseGrade]>(cachedAt: .now, value: courseGrades)
        } catch {
            return
        }
    }
}
