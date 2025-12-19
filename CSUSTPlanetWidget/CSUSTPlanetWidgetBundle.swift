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
    var body: some Widget {
        DormElectricityWidget()
        GradeAnalysisWidget()
        TodayCoursesWidget()
        WeeklyCoursesWidget()
        UrgentCoursesWidget()

        CourseStatusWidgetLiveActivity()
    }
}
