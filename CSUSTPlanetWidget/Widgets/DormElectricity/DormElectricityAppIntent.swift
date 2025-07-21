//
//  DormElectricityAppIntent.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/20.
//

import AppIntents
import SwiftData
import WidgetKit

struct DormElectricityAppIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "宿舍电量"
    static var description = IntentDescription("选择一个宿舍查看其用电情况")

    @Parameter(title: "宿舍")
    var dormitory: DormEntity?
}
