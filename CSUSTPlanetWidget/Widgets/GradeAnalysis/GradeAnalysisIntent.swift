//
//  GradeAnalysisIntent.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/7/22.
//

import AppIntents

enum ChartType: String, AppEnum {
    case semesterAverage = "各学期平均成绩"
    case semesterGPA = "各学期GPA"
    case gpaDistribution = "GPA分布"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "图表类型"
    static var caseDisplayRepresentations: [ChartType: DisplayRepresentation] = [
        .semesterAverage: "各学期平均成绩",
        .semesterGPA: "各学期GPA",
        .gpaDistribution: "GPA分布"
    ]

    static func defaultResult() async -> ChartType? {
        .gpaDistribution
    }
}

struct GradeAnalysisIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "成绩分析"
    static var description = IntentDescription("分析您的成绩数据，提供详细的成绩统计和趋势分析。")

    @Parameter(title: "选择图表类型", default: .gpaDistribution)
    var chartType: ChartType
}
