//
//  GradeAnalysisEntryView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/22.
//

import Charts
import SwiftUI
import WidgetKit

struct GradeAnalysisEntryView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily

    var entry: GradeAnalysisProvider.Entry

    // MARK: - Body

    var body: some View {
        Group {
            if let data = entry.data, let lastUpdated = entry.lastUpdated {
                contentView(configuration: entry.configuration, data: data, lastUpdated: lastUpdated)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ZStack(alignment: .topTrailing) {
                    emptyView.frame(maxWidth: .infinity, maxHeight: .infinity)
                    refreshButtonView
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .widgetURL(URL(string: "csustplanet://features/grade-analysis"))
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Empty View

    var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "gearshape.fill")
                .font(.title)
                .foregroundStyle(.gray.opacity(0.8))
            VStack(spacing: 4) {
                Text("暂无成绩数据")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("请点击右上角刷新按钮尝试刷新成绩数据")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Refresh Button View

    var refreshButtonView: some View {
        Button(intent: RefreshGradeAnalysisTimelineIntent()) {
            Image(systemName: "arrow.clockwise.circle")
        }
        .foregroundStyle(Color.accentColor)
        .buttonStyle(.plain)
    }

    // MARK: - Content View

    @ViewBuilder
    func contentView(configuration: GradeAnalysisAppIntent, data: GradeAnalysisData, lastUpdated: Date) -> some View {
        if family == .systemSmall || family == .systemMedium {
            HStack(spacing: 2) {
                VStack(spacing: 0) {
                    headerView()
                    Divider().padding(.vertical, 4)
                    statsView(data: data, lastUpdated: lastUpdated)
                }

                if family == .systemMedium {
                    chartView(data: data, configuration: configuration)
                }
            }
        } else {
            VStack(spacing: 0) {
                headerView(lastUpdated: lastUpdated)
                Divider().padding(.vertical, 4)
                statsView(data: data, lastUpdated: lastUpdated)
                    .padding(.bottom, 4)
                chartView(data: data, configuration: configuration)
            }
        }
    }

    // MARK: - Header View

    @ViewBuilder
    func headerView(lastUpdated: Date? = nil) -> some View {
        HStack(alignment: .center, spacing: 4) {
            Text("成绩分析")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.primary)
            if let lastUpdated = lastUpdated {
                LastUpdatedDateView(
                    lastUpdated: lastUpdated,
                    font: .system(size: 10, weight: .medium),
                    foregroundStyle: .secondary
                )
            }
            Spacer()
            refreshButtonView
        }
    }

    // MARK: - Stats View

    @ViewBuilder
    func statsView(data: GradeAnalysisData, lastUpdated: Date) -> some View {
        if family == .systemSmall || family == .systemMedium {
            VStack(alignment: .center, spacing: 0) {
                HStack(alignment: .center, spacing: 0) {
                    statItemView(title: "GPA", value: String(format: "%.2f", data.overallGPA), color: ColorUtil.dynamicColor(point: data.overallGPA))
                    statItemView(title: "总学分", value: String(format: "%.1f", data.totalCredits), color: .blue)
                    statItemView(title: "课程数", value: "\(data.totalCourses)", color: .purple)
                }
                .frame(maxHeight: .infinity)
                HStack(alignment: .center, spacing: 0) {
                    statItemView(title: "平均成绩", value: String(format: "%.2f", data.overallAverageGrade), color: ColorUtil.dynamicColor(grade: data.overallAverageGrade))
                    statItemView(title: "加权平均", value: String(format: "%.2f", data.weightedAverageGrade), color: ColorUtil.dynamicColor(grade: data.weightedAverageGrade))
                }
                .frame(maxHeight: .infinity)
                LastUpdatedDateView(
                    lastUpdated: lastUpdated,
                    font: .system(size: 10, weight: .medium),
                    foregroundStyle: .secondary
                )
                .multilineTextAlignment(.center)
            }
        } else {
            HStack(spacing: 0) {
                statItemView(title: "GPA", value: String(format: "%.2f", data.overallGPA), color: ColorUtil.dynamicColor(point: data.overallGPA))
                statItemView(title: "平均成绩", value: String(format: "%.2f", data.overallAverageGrade), color: ColorUtil.dynamicColor(grade: data.overallAverageGrade))
                statItemView(title: "加权平均", value: String(format: "%.2f", data.weightedAverageGrade), color: ColorUtil.dynamicColor(grade: data.weightedAverageGrade))
                statItemView(title: "总学分", value: String(format: "%.1f", data.totalCredits), color: .blue)
                statItemView(title: "课程数", value: "\(data.totalCourses)", color: .purple)
            }
        }
    }

    // MARK: - Stat Item View

    @ViewBuilder
    func statItemView(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Chart View

    @ViewBuilder
    func chartView(data: GradeAnalysisData, configuration: GradeAnalysisAppIntent) -> some View {
        switch configuration.chartType {
        case .semesterAverage:
            let min = data.semesterAverageGrades.min(by: { $0.average < $1.average })?.average ?? 0
            let max = data.semesterAverageGrades.max(by: { $0.average < $1.average })?.average ?? 0
            let displayMin = min - 5 > 0 ? min - 5 : 0
            let displayMax = max + 5
            Chart(data.semesterAverageGrades, id: \.semester) { item in
                LineMark(
                    x: .value("学期", item.semester),
                    y: .value("平均成绩", item.average)
                )
                .foregroundStyle(ColorUtil.dynamicColor(grade: item.average))
                .lineStyle(StrokeStyle(lineWidth: 3))
                PointMark(
                    x: .value("学期", item.semester),
                    y: .value("平均成绩", item.average)
                )
                .foregroundStyle(ColorUtil.dynamicColor(grade: item.average))
                .annotation(position: .top) {
                    Text(String(format: "%.1f", item.average))
                        .font(.system(size: 10))
                        .padding(4)
                        .background(ColorUtil.dynamicColor(grade: item.average).opacity(0.2))
                        .cornerRadius(4)
                }
            }
            .chartXAxis(family == .systemMedium ? .hidden : .automatic)
            .chartYScale(domain: displayMin...displayMax)
        case .semesterGPA:
            let min = data.semesterGPAs.min(by: { $0.gpa < $1.gpa })?.gpa ?? 0
            let max = data.semesterGPAs.max(by: { $0.gpa < $1.gpa })?.gpa ?? 0
            let displayMin = min - 0.5 > 0 ? min - 0.5 : 0
            let displayMax = max + 0.5
            Chart(data.semesterGPAs, id: \.semester) { item in
                LineMark(
                    x: .value("学期", item.semester),
                    y: .value("GPA", item.gpa)
                )
                .foregroundStyle(ColorUtil.dynamicColor(point: item.gpa))
                .lineStyle(StrokeStyle(lineWidth: 3))
                PointMark(
                    x: .value("学期", item.semester),
                    y: .value("GPA", item.gpa)
                )
                .foregroundStyle(ColorUtil.dynamicColor(point: item.gpa))
                .annotation(position: .top) {
                    Text(String(format: "%.2f", item.gpa))
                        .font(.system(size: 10))
                        .padding(4)
                        .background(ColorUtil.dynamicColor(point: item.gpa).opacity(0.2))
                        .cornerRadius(4)
                }
            }
            .chartXAxis(family == .systemMedium ? .hidden : .automatic)
            .chartYScale(domain: displayMin...displayMax)
        case .gpaDistribution:
            Chart(data.gradePointDistribution, id: \.gradePoint) { item in
                BarMark(
                    x: .value("绩点", String(format: "%.1f", item.gradePoint)),
                    y: .value("课程数", item.count)
                )
                .foregroundStyle(ColorUtil.dynamicColor(point: item.gradePoint))
                .annotation(position: .top) {
                    Text("\(item.count)")
                        .font(.system(size: 10).bold())
                        .foregroundColor(ColorUtil.dynamicColor(point: item.gradePoint))
                        .padding(4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .chartXAxis {
                if family == .systemMedium {
                    AxisMarks(values: .automatic) {
                        AxisValueLabel()
                            .font(.system(size: 8))
                    }
                } else {
                    AxisMarks()
                }
            }
        }

    }
}
