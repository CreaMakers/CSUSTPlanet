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
    @EnvironmentObject var authManager: AuthManager
    @StateObject var viewModel = GradeAnalysisViewModel()

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

    private func summaryCard(_ gradeAnalysisData: GradeAnalysisData, _ weightedAverageGrade: Double?) -> some View {
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
                if let weightedAverageGrade = weightedAverageGrade {
                    statisticItem(
                        title: "加权平均成绩",
                        value: String(format: "%.2f", weightedAverageGrade),
                        color: ColorHelper.dynamicColor(grade: weightedAverageGrade)
                    )
                    Spacer()
                }
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

    private func analysisContent(_ gradeAnalysisData: GradeAnalysisData, _ weightedAverageGrade: Double?) -> some View {
        VStack(spacing: 20) {
            summaryCard(gradeAnalysisData, weightedAverageGrade)
            semesterAnalysisSection(gradeAnalysisData)
        }
    }

    // MARK: - Empty State Section

    private var emptyStateSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
                .padding(.bottom, 8)

            Text("暂无成绩数据")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Shareable View

    @ViewBuilder
    private var shareableView: some View {
        if let gradeAnalysisData = viewModel.data, let weightedAverageGrade = viewModel.weightedAverageGrade {
            analysisContent(gradeAnalysisData, weightedAverageGrade)
                .padding(.vertical)
                .frame(width: UIScreen.main.bounds.width)
                .background(Color(.systemGroupedBackground))
                .environment(\.colorScheme, colorScheme)
        } else {
            emptyStateSection
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let data = viewModel.data {
                ZStack(alignment: .topTrailing) {
                    ScrollView {
                        analysisContent(data, viewModel.weightedAverageGrade)
                    }

                    if let updated = viewModel.localDataLastUpdated {
                        Text("本地缓存 · \(updated)")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.primary.opacity(0.6), lineWidth: 1)
                            )
                            .foregroundColor(.primary)
                            .padding(.trailing, 18)
                            .padding(.top, 8)
                    }
                }
            } else {
                emptyStateSection
            }
        }
        .task {
            viewModel.getCourseGrades(authManager.eduHelper)
        }
        .toast(isPresenting: $viewModel.isShowingError) {
            AlertToast(type: .error(.red), title: "错误", subTitle: viewModel.errorMessage)
        }
        .toast(isPresenting: $viewModel.isShowingSuccess) {
            AlertToast(type: .complete(.green), title: "图片保存成功")
        }
        .toast(isPresenting: $viewModel.isShowingWarning) {
            AlertToast(displayMode: .banner(.slide), type: .systemImage("exclamationmark.triangle", .yellow), title: "警告", subTitle: viewModel.warningMessage)
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
                .disabled(viewModel.isLoading || viewModel.data == nil)
            }
            ToolbarItem(placement: .primaryAction) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.9, anchor: .center)
                } else {
                    Button(action: { viewModel.getCourseGrades(authManager.eduHelper) }) {
                        Label("刷新成绩分析", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }
}
