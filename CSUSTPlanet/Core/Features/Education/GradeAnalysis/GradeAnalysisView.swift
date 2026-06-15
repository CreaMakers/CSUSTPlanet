//
//  GradeAnalysisView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import AlertToast
import CSUSTKit
import Charts
import SwiftUI

struct GradeAnalysisView: View {
    @State var viewModel = GradeAnalysisViewModel()

    // MARK: - Body

    var body: some View {
        Group {
            if let data = viewModel.analysisData {
                CustomScrollView {
                    analysisContent(data)
                }
            } else {
                ContentUnavailableView("暂无成绩数据", systemImage: "doc.text.magnifyingglass", description: Text("当前没有找到成绩数据"))
            }
        }
        .task { await viewModel.loadInitial() }
        .safeRefreshable { await viewModel.loadGradeAnalysis() }
        .errorToast($viewModel.errorToast)
        .successToast($viewModel.successToast)
        #if os(iOS)
        .sheet(isPresented: $viewModel.isShowingShareSheet) { ShareSheet(items: [viewModel.shareContent ?? "分享错误"]) }
        #endif
        .navigationTitle("成绩分析")
        .largeToolbarTitle()
        .toolbar {
            #if os(iOS)
            ToolbarItemGroup(placement: .secondaryAction) {
                Button(action: { viewModel.showShareSheet(shareableView) }) {
                    Label("分享", systemImage: "square.and.arrow.up")
                }
                .disabled(viewModel.isLoadingAnalysis || viewModel.courseGradesData?.value.isEmpty == true)
                Button(action: { viewModel.saveToPhotoAlbum(shareableView) }) {
                    Label("保存结果到相册", systemImage: "photo")
                }
                .disabled(viewModel.isLoadingAnalysis || viewModel.courseGradesData?.value.isEmpty == true)
            }
            #endif
            ToolbarItem(placement: .primaryAction) {
                Button(asyncAction: viewModel.loadGradeAnalysis) {
                    if viewModel.isLoadingAnalysis {
                        ProgressView().smallControlSizeOnMac()
                    } else {
                        Label("刷新成绩分析", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(viewModel.isLoadingAnalysis)
            }
        }
    }

    // MARK: - Statistic Item

    @ViewBuilder
    func statisticItem(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
        }
    }

    // MARK: - Summary Card

    @ViewBuilder
    private func summaryCard(_ gradeAnalysisData: GradeAnalysisData) -> some View {
        CustomGroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("学习总览")
                    .font(.headline)
                    .padding(.bottom, 4)
                HStack {
                    statisticItem(title: "课程总数", value: "\(gradeAnalysisData.totalCourses)", color: .purple)
                    Spacer()
                    statisticItem(title: "总学分", value: String(format: "%.1f", gradeAnalysisData.totalCredits), color: .blue)
                    Spacer()
                    statisticItem(title: "总学时", value: "\(gradeAnalysisData.totalHours)", color: .red)
                }
                Divider()
                HStack {
                    statisticItem(
                        title: "平均成绩",
                        value: String(format: "%.2f", gradeAnalysisData.overallAverageGrade),
                        color: ColorUtil.dynamicColor(grade: gradeAnalysisData.overallAverageGrade)
                    )
                    Spacer()
                    statisticItem(
                        title: "加权平均成绩",
                        value: String(format: "%.2f", gradeAnalysisData.weightedAverageGrade),
                        color: ColorUtil.dynamicColor(grade: gradeAnalysisData.weightedAverageGrade)
                    )
                    Spacer()
                    statisticItem(
                        title: "平均绩点",
                        value: String(format: "%.2f", gradeAnalysisData.overallGPA),
                        color: ColorUtil.dynamicColor(point: gradeAnalysisData.overallGPA)
                    )
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Semester Analysis Section

    @ViewBuilder
    private func semesterAnalysisSection(_ gradeAnalysisData: GradeAnalysisData, isShareable: Bool = false) -> some View {
        VStack(spacing: 30) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(isShareable ? "学期\(viewModel.selectedChartType.rawValue)" : "学期平均成绩/GPA")
                        .font(.headline)
                    Spacer()
                    if !isShareable {
                        Picker("图表类型", selection: $viewModel.selectedChartType.withAnimation()) {
                            ForEach(GradeAnalysisViewModel.ChartType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .fixedSize()
                    }
                }
                .padding(.horizontal)

                if viewModel.selectedChartType == .averageGrade {
                    Chart(gradeAnalysisData.semesterAverageGrades, id: \.semester) { item in
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
                    .chartYAxis {
                        AxisMarks(values: .automatic(desiredCount: 5))
                    }
                    .frame(height: 250)
                    .padding()
                } else {
                    Chart(gradeAnalysisData.semesterGPAs, id: \.semester) { item in
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
                    .chartYAxis {
                        AxisMarks(values: .automatic(desiredCount: 5))
                    }
                    .frame(height: 250)
                    .padding()
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(isShareable ? "\(viewModel.selectedDistributionChartType.rawValue)分布" : "绩点/成绩分布")
                        .font(.headline)
                    Spacer()
                    if !isShareable {
                        Picker("分布类型", selection: $viewModel.selectedDistributionChartType.withAnimation()) {
                            ForEach(GradeAnalysisViewModel.DistributionChartType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .fixedSize()
                    }
                }
                .padding(.horizontal)

                Chart(gradeAnalysisData.gradePointDistribution, id: \.gradePoint) { item in
                    BarMark(
                        x: .value(
                            viewModel.selectedDistributionChartType == .gradePoint ? "绩点" : "成绩段",
                            viewModel.selectedDistributionChartType == .gradePoint
                                ? String(format: "%.1f", item.gradePoint)
                                : (GradeAnalysisViewModel.gradePointToRangeMap[item.gradePoint] ?? "")
                        ),
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
                    AxisMarks {
                        AxisValueLabel()
                            .font(viewModel.selectedDistributionChartType == .gradeRange ? .system(size: 9) : .system(size: 11))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }
                .frame(height: 220)
                .padding()
            }
        }
    }

    // MARK: - Analysis Content

    @ViewBuilder
    private func analysisContent(_ gradeAnalysisData: GradeAnalysisData, isShareable: Bool = false) -> some View {
        VStack(spacing: 20) {
            summaryCard(gradeAnalysisData)
            semesterAnalysisSection(gradeAnalysisData, isShareable: isShareable)
        }
    }

    // MARK: - Shareable View

    #if os(iOS)
    @Environment(\.colorScheme) var colorScheme

    @ViewBuilder
    private var shareableView: some View {
        if let gradeAnalysisData = viewModel.analysisData {
            analysisContent(gradeAnalysisData, isShareable: true)
                .padding(.vertical)
                .frame(width: UIScreen.main.bounds.width)
                .background(Color(PlatformColor.systemGroupedBackground))
                .environment(\.colorScheme, colorScheme)
        } else {
            ContentUnavailableView("暂无成绩数据", systemImage: "doc.text.magnifyingglass", description: Text("当前没有找到成绩数据"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    #endif
}
