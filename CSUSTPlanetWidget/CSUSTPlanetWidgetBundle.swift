//
//  CSUSTPlanetWidgetBundle.swift
//  CSUSTPlanetWidget
//
//  Created by Zhe_Learn on 2025/7/20.
//

import AppIntents
import SwiftData
import SwiftUI
import WidgetKit

@main
struct CSUSTPlanetWidgetBundle: WidgetBundle {
    init() {
        let asyncDependency: @Sendable () async -> ModelContainer = { @MainActor in
            return SharedModel.container
        }
        AppDependencyManager.shared.add(key: "ModelContainer", dependency: asyncDependency)
    }

    var body: some Widget {
        DormElectricityWidget()
        GradeAnalysisWidget()
        TodayCoursesWidget()
    }
}
