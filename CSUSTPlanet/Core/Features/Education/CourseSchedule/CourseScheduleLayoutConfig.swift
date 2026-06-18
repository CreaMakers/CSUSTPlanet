//
//  CourseScheduleLayoutConfig.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/6/18.
//

import SwiftUI

struct CourseScheduleLayoutConfig {
    let isWideSize: Bool
    let colSpacing: CGFloat
    let rowSpacing: CGFloat
    let horizontalPadding: CGFloat
    let timeColWidth: CGFloat
    let sectionHeight: CGFloat
}

struct CourseScheduleLayoutConfigKey: EnvironmentKey {
    static var defaultValue = CourseScheduleLayoutConfig(
        isWideSize: false,
        colSpacing: 2,
        rowSpacing: 2,
        horizontalPadding: 8,
        timeColWidth: 30,
        sectionHeight: 60,
    )
}

extension EnvironmentValues {
    var courseScheduleLayoutConfig: CourseScheduleLayoutConfig {
        get { self[CourseScheduleLayoutConfigKey.self] }
        set { self[CourseScheduleLayoutConfigKey.self] = newValue }
    }
}
