//
//  RefreshUrgentCoursesTimelineIntent.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/10/13.
//

import AppIntents
import Foundation
import WidgetKit

struct RefreshUrgentCoursesTimelineIntent: AppIntent {
    static var title: LocalizedStringResource = "刷新待提交作业时间线"
    static var isDiscoverable: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadTimelines(ofKind: "UrgentCoursesWidget")
        return .result()
    }
}
