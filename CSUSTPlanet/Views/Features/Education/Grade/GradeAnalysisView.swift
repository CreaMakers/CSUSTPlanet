//
//  GradeAnalysisView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import AlertToast
import Charts
import CSUSTKit
import SwiftUI

struct GradeAnalysisView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject var viewModel: GradeAnalysisViewModel
    
    init(eduHelper: EduHelper) {
        self._viewModel = StateObject(wrappedValue: GradeAnalysisViewModel(eduHelper: eduHelper))
    }
    
    // MARK: - Statistic Item
    
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
    
    private func summaryCard(_ gradeAnalysisData: GradeAnalysisData, _ weightedAverageGrade: Double) -> some View {
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
                    color: ColorHelper.dynamicColor(grade: gradeAnalysisData.overallAverageGrade)
                )
                Spacer()
                statisticItem(
                    title: "加权平均成绩",
                    value: String(format: "%.2f", weightedAverageGrade),
                    color: ColorHelper.dynamicColor(grade: weightedAverageGrade)
                )
                Spacer()
                statisticItem(
                    title: "平均绩点",
                    value: String(format: "%.2f", gradeAnalysisData.overallGPA),
                    color: ColorHelper.dynamicColor(point: gradeAnalysisData.overallGPA)
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    // MARK: - Semester Analysis Section
    
    private func semesterAnalysisSection(_ gradeAnalysisData: GradeAnalysisData) -> some View {
        VStack(spacing: 30) {
            VStack(alignment: .leading, spacing: 8) {
                Text("学期平均成绩")
                    .font(.headline)
                    .padding(.horizontal)
                    
                Chart(gradeAnalysisData.semesterAverageGrades, id: \.semester) { item in
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
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }
                .frame(height: 250)
                .padding()
            }
                
            VStack(alignment: .leading, spacing: 8) {
                Text("学期GPA")
                    .font(.headline)
                    .padding(.horizontal)
                    
                Chart(gradeAnalysisData.semesterGPAs, id: \.semester) { item in
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
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }
                .frame(height: 250)
                .padding()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("绩点分布")
                    .font(.headline)
                    .padding(.horizontal)
                Chart(gradeAnalysisData.gradePointDistribution, id: \.gradePoint) { item in
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
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }
                .frame(height: 220)
                .padding()
            }
        }
    }

    // MARK: - Analysis Content
    
    private var analysisContent: some View {
        VStack(spacing: 20) {
            if viewModel.isQuerying {
                ProgressView("正在加载成绩数据...")
                    .padding()
            } else {
                if let gradeAnalysisData = viewModel.gradeAnalysisData, let weightedAverageGrade = viewModel.weightedAverageGrade {
                    summaryCard(gradeAnalysisData, weightedAverageGrade)
                    semesterAnalysisSection(gradeAnalysisData)
                } else {
                    Text("暂无成绩数据")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Shareable View

    private var shareableView: some View {
        analysisContent
            .padding(.vertical)
            .background(Color(.systemGroupedBackground))
            .environment(\.colorScheme, colorScheme)
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            analysisContent
        }
        .task {
            viewModel.getCourseGrades()
        }
        .toast(isPresenting: $viewModel.isShowingError) {
            AlertToast(type: .error(.red), title: "错误", subTitle: viewModel.errorMessage)
        }
        .toast(isPresenting: $viewModel.isShowingSuccess) {
            AlertToast(type: .complete(.green), title: "图片保存成功")
        }
        .sheet(isPresented: $viewModel.isShowingShareSheet) { ShareSheet(items: [viewModel.shareContent!]) }
        .navigationTitle("成绩分析")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { viewModel.showShareSheet(shareableView) }) {
                        Label("分享", systemImage: "square.and.arrow.up")
                    }
                    Button(action: { viewModel.saveToPhotoAlbum(shareableView) }) {
                        Label("保存结果到相册", systemImage: "photo")
                    }
                } label: {
                    Label("更多操作", systemImage: "ellipsis.circle")
                }
                .disabled(viewModel.isQuerying || viewModel.gradeAnalysisData == nil)
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.getCourseGrades()
                } label: {
                    Label("刷新成绩分析", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isQuerying)
            }
        }
    }
}
