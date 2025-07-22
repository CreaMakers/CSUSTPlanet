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

    var body: some View {
        if let gradeAnalysis = entry.gradeAnalysis {
            switch family {
            case .systemSmall:
                systemSmall(gradeAnalysis: gradeAnalysis)
            case .systemMedium:
                systemMedium(gradeAnalysis: gradeAnalysis)
            case .systemLarge:
                systemLarge(gradeAnalysis: gradeAnalysis)
            default:
                systemSmall(gradeAnalysis: gradeAnalysis)
            }
        } else {
            Text("请先在App内查询成绩分析")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }

    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd HH:mm"
        return dateFormatter
    }()

    func systemSmall(gradeAnalysis: GradeAnalysisEntry.GradeAnalysis) -> some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.purple)
                Text("成绩分析")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Button(intent: RefreshGradeAnalysisTimelineIntent()) {
                    Image(systemName: "arrow.clockwise.circle")
                }
                .foregroundStyle(.blue)
                .buttonStyle(.plain)
            }

            Spacer()

            HStack {
                VStack {
                    Text("课程数")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text("\(gradeAnalysis.totalCourses)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.purple)
                }
                .frame(maxWidth: .infinity)
                VStack {
                    Text("总学分")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f", gradeAnalysis.totalCredits))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.blue)
                }
                .frame(maxWidth: .infinity)
                VStack {
                    Text("总学时")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("\(gradeAnalysis.totalHours)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.red)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)

            Divider().padding(.vertical, 2)

            HStack {
                VStack {
                    Text("平均成绩")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f", gradeAnalysis.overallAverageGrade))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(ColorHelper.dynamicColor(grade: gradeAnalysis.overallAverageGrade))
                }
                .frame(maxWidth: .infinity)
                Spacer()
                VStack {
                    Text("平均绩点")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f", gradeAnalysis.overallGPA))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(ColorHelper.dynamicColor(point: gradeAnalysis.overallGPA))
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)

            Text("更新时间: \(dateFormatter.string(from: gradeAnalysis.lastUpdated))")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    func systemMedium(gradeAnalysis: GradeAnalysisEntry.GradeAnalysis) -> some View {
        HStack {
            systemSmall(gradeAnalysis: gradeAnalysis)
            chartView(gradeAnalysis: gradeAnalysis)
        }
    }

    func systemLarge(gradeAnalysis: GradeAnalysisEntry.GradeAnalysis) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.purple)
                Text("成绩分析")
                    .font(.system(size: 16, weight: .bold))
                Text("更新时间: \(dateFormatter.string(from: gradeAnalysis.lastUpdated))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Button(intent: RefreshGradeAnalysisTimelineIntent()) {
                    Image(systemName: "arrow.clockwise.circle")
                }
                .foregroundStyle(.blue)
                .buttonStyle(.plain)
            }
            HStack {
                VStack {
                    Text("课程数")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("\(gradeAnalysis.totalCourses)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.purple)
                }
                .frame(maxWidth: .infinity)
                VStack {
                    Text("总学分")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f", gradeAnalysis.totalCredits))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.blue)
                }
                .frame(maxWidth: .infinity)
                VStack {
                    Text("总学时")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("\(gradeAnalysis.totalHours)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.red)
                }
                .frame(maxWidth: .infinity)
                VStack {
                    Text("平均成绩")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f", gradeAnalysis.overallAverageGrade))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(ColorHelper.dynamicColor(grade: gradeAnalysis.overallAverageGrade))
                }
                .frame(maxWidth: .infinity)
                VStack {
                    Text("平均绩点")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f", gradeAnalysis.overallGPA))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(ColorHelper.dynamicColor(point: gradeAnalysis.overallGPA))
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            chartView(gradeAnalysis: gradeAnalysis)
        }
    }

    func chartView(gradeAnalysis: GradeAnalysisEntry.GradeAnalysis) -> some View {
        Group {
            switch entry.configuration.chartType {
            case .semesterAverage:
                Chart(gradeAnalysis.semesterAverageGrades, id: \.semester) { item in
                    LineMark(
                        x: .value("学期", item.semester),
                        y: .value("平均成绩", item.average)
                    )
                    .foregroundStyle(ColorHelper.dynamicColor(grade: item.average))
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    PointMark(
                        x: .value("学期", item.semester),
                        y: .value("平均成绩", item.average)
                    )
                    .foregroundStyle(ColorHelper.dynamicColor(grade: item.average))
                    .annotation(position: .top) {
                        Text(String(format: "%.1f", item.average))
                            .font(.system(size: 10))
                            .padding(4)
                            .background(ColorHelper.dynamicColor(grade: item.average).opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            case .semesterGPA:
                Chart(gradeAnalysis.semesterGPAs, id: \.semester) { item in
                    LineMark(
                        x: .value("学期", item.semester),
                        y: .value("GPA", item.gpa)
                    )
                    .foregroundStyle(ColorHelper.dynamicColor(point: item.gpa))
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    PointMark(
                        x: .value("学期", item.semester),
                        y: .value("GPA", item.gpa)
                    )
                    .foregroundStyle(ColorHelper.dynamicColor(point: item.gpa))
                    .annotation(position: .top) {
                        Text(String(format: "%.2f", item.gpa))
                            .font(.system(size: 10))
                            .padding(4)
                            .background(ColorHelper.dynamicColor(point: item.gpa).opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            case .gpaDistribution:
                Chart(gradeAnalysis.gradePointDistribution, id: \.gradePoint) { item in
                    BarMark(
                        x: .value("绩点", String(format: "%.1f", item.gradePoint)),
                        y: .value("课程数", item.count)
                    )
                    .foregroundStyle(ColorHelper.dynamicColor(point: item.gradePoint))
                    .annotation(position: .top) {
                        Text("\(item.count)")
                            .font(.system(size: 10).bold())
                            .foregroundColor(ColorHelper.dynamicColor(point: item.gradePoint))
                            .padding(4)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
        }
    }
}

#Preview(as: .systemSmall) {
    GradeAnalysisWidget()
} timeline: {
    mockEntry(configuration: nil)
}

#Preview(as: .systemMedium) {
    GradeAnalysisWidget()
} timeline: {
    let intent = {
        let intent = GradeAnalysisIntent()
        intent.chartType = .gpaDistribution
        return intent
    }()
    mockEntry(configuration: intent)
}

#Preview(as: .systemLarge) {
    GradeAnalysisWidget()
} timeline: {
    let intent = {
        let intent = GradeAnalysisIntent()
        intent.chartType = .gpaDistribution
        return intent
    }()
    mockEntry(configuration: intent)
}
