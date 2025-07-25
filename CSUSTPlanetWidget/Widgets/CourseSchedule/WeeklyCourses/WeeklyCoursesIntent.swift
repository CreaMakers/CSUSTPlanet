//
//  WeeklyCoursesIntent.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/7/25.
//

import AppIntents
import Foundation

struct WeeklyCoursesIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "本周课程"
    static var description = IntentDescription("查看本周的课程安排")
}
