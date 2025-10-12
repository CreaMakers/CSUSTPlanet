//
//  CSUSTPlanetWidgetBundle.swift
//  CSUSTPlanetWidget
//
//  Created by Zhe_Learn on 2025/7/20.
//

import AppIntents
import SwiftUI
import WidgetKit

@main
struct CSUSTPlanetWidgetBundle: WidgetBundle {
    init() {
        RealmManager.shared.setup()
    }

    var body: some Widget {
        DormElectricityWidget()
        GradeAnalysisWidget()
        TodayCoursesWidget()
        WeeklyCoursesWidget()
    }
}
