//
//  TodayCoursesIntent.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/7/23.
//

import AppIntents
import Foundation

struct TodayCoursesIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "今日课程"
    static var description = IntentDescription("查看今天的课程安排")
}
