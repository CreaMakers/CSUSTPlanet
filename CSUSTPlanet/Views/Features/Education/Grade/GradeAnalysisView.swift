//
//  GradeAnalysisView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import Charts
import CSUSTKit
import SwiftUI

struct GradeAnalysisView: View {
    @StateObject var viewModel: GradeAnalysisViewModel
    
    init(eduHelper: EduHelper) {
        self._viewModel = StateObject(wrappedValue: GradeAnalysisViewModel(eduHelper: eduHelper))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isQuerying {
                    ProgressView("正在加载成绩数据...")
                        .padding()
                } else {
                    summaryCard
                    
                    semesterAnalysisSection
                }
            }
            .padding(.vertical)
        }
        .task {
            viewModel.getCourseGrades()
        }
        .alert("错误", isPresented: $viewModel.isShowingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .navigationTitle("成绩分析")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        viewModel.getCourseGrades()
                    } label: {
                        Label("刷新成绩分析", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isQuerying)
                } label: {
                    Label("操作", systemImage: "ellipsis.circle")
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学习总览")
                .font(.headline)
                .padding(.bottom, 4)
            HStack {
                StatisticItem(
                    title: "课程总数",
                    value: "\(viewModel.totalCourses)",
                    color: .purple
                )
                Spacer()
                StatisticItem(
                    title: "总学分",
                    value: String(format: "%.1f", viewModel.totalCredits),
                    color: .blue
                )
                Spacer()
                StatisticItem(
                    title: "总学时",
                    value: "\(viewModel.totalHours)",
                    color: .red
                )
            }
            Divider()
            HStack {
                StatisticItem(
                    title: "平均成绩",
                    value: String(format: "%.2f", viewModel.overallAverageGrade),
                    color: ColorHelper.dynamicColor(grade: viewModel.overallAverageGrade)
                )
                Spacer()
                StatisticItem(
                    title: "平均绩点",
                    value: String(format: "%.2f", viewModel.overallGPA),
                    color: ColorHelper.dynamicColor(point: viewModel.overallGPA)
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    private struct StatisticItem: View {
        let title: String
        let value: String
        let color: Color
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title2.bold())
                    .foregroundStyle(color)
            }
        }
    }
    
    private var semesterAnalysisSection: some View {
        VStack(spacing: 30) {
            VStack(alignment: .leading, spacing: 8) {
                Text("学期平均成绩")
                    .font(.headline)
                    .padding(.horizontal)
                    
                Chart(viewModel.semesterAverageGrades, id: \.semester) { item in
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
                    
                Chart(viewModel.semesterGPAs, id: \.semester) { item in
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
                Chart(viewModel.gradePointDistribution, id: \.gradePoint) { item in
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
}
