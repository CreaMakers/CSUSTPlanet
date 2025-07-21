//
//  RefreshElectricityIntent.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/21.
//

import AppIntents
import WidgetKit

struct RefreshElectricityTimelineIntent: AppIntent {
    static var title: LocalizedStringResource = "刷新宿舍电量时间线"
    static var isDiscoverable: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadTimelines(ofKind: "DormElectricityWidget")
        return .result()
    }
}
