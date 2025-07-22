//
//  RefreshGradeAnalysisTimelineIntent.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/7/22.
//

import AppIntents
import WidgetKit

struct RefreshGradeAnalysisTimelineIntent: AppIntent {
    static var title: LocalizedStringResource = "刷新成绩分析时间线"
    static var isDiscoverable: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadTimelines(ofKind: "GradeAnalysisWidget")
        return .result()
    }
}
