//
//  GradeQueryView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import AlertToast
import CSUSTKit
import SwiftUI

struct GradeQueryView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @StateObject var viewModel = GradeQueryViewModel()

    // MARK: - Stat Item

    @ViewBuilder
    private func statItem(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .center, spacing: 8) {
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

    // MARK: - Stats Section

    @ViewBuilder
    private var statsSection: some View {
        VStack(alignment: .center) {
            if let analysis = viewModel.analysis {
                HStack(spacing: 10) {
                    statItem(title: "GPA", value: String(format: "%.2f", analysis.overallGPA), color: ColorUtil.dynamicColor(point: analysis.overallGPA))
                    statItem(title: "平均成绩", value: String(format: "%.2f", analysis.overallAverageGrade), color: ColorUtil.dynamicColor(grade: analysis.overallAverageGrade))
                    statItem(title: "加权平均成绩", value: String(format: "%.2f", analysis.weightedAverageGrade), color: ColorUtil.dynamicColor(grade: analysis.weightedAverageGrade))
                    statItem(title: "已修总学分", value: String(format: "%.1f", analysis.totalCredits), color: .blue)
                    statItem(title: "课程总数", value: "\(analysis.totalCourses)", color: .purple)
                }
                .frame(maxWidth: .infinity)
            } else {
                HStack(spacing: 10) {
                    statItem(title: "GPA", value: "0.0", color: .primary)
                    statItem(title: "平均成绩", value: "0.0", color: .primary)
                    statItem(title: "加权平均成绩", value: "0.0", color: .primary)
                    statItem(title: "已修总学分", value: "0.0", color: .primary)
                    statItem(title: "课程总数", value: "0", color: .primary)
                }
                .frame(maxWidth: .infinity)
                .redacted(reason: viewModel.isLoading ? .placeholder : [])
            }
        }
    }

    // MARK: - Empty State Section

    @ViewBuilder
    private var emptyStateSection: some View {
        if viewModel.searchText.isEmpty {
            ContentUnavailableView {
                Label("暂无成绩记录", systemImage: "doc.text.magnifyingglass")
            } description: {
                Text("当前筛选条件下没有找到成绩记录")
            }
        } else {
            ContentUnavailableView.search(text: viewModel.searchText)
        }
    }

    // MARK: - Grade Card

    @ViewBuilder
    private func gradeCardContent(courseGrade: EduHelper.CourseGrade) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(courseGrade.courseAttribute)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.2))
                        .foregroundColor(Color.accentColor)
                        .cornerRadius(4)
                    Text(courseGrade.courseName)
                        .font(.headline)
                }
                if !courseGrade.groupName.isEmpty {
                    Text("(\(courseGrade.groupName))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 20) {
                    HStack(spacing: 4) {
                        Text("学分：")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", courseGrade.credit))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 4) {
                        Text("绩点：")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", courseGrade.gradePoint))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(ColorUtil.dynamicColor(point: courseGrade.gradePoint))
                    }
                }
            }

            Spacer()

            Text("\(courseGrade.grade)分")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(ColorUtil.dynamicColor(grade: Double(courseGrade.grade)))
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func gradeCard(courseGrade: EduHelper.CourseGrade) -> some View {
        TrackLink(destination: GradeDetailView(courseGrade: courseGrade)) {
            gradeCardContent(courseGrade: courseGrade)
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if !viewModel.filteredCourseGrades.isEmpty {
                // 这里是修复跳转页面选中状态问题
                List(selection: viewModel.isSelectionMode ? $viewModel.selectedItems : .constant(Set<GradeQueryViewModel.SelectionItem>())) {
                    ForEach(viewModel.groupedFilteredCourseGrades, id: \.semester) { group in
                        Section {
                            DisclosureGroup(isExpanded: viewModel.bindingForSemester(group.semester)) {
                                ForEach(group.grades, id: \.courseID) { courseGrade in
                                    gradeCard(courseGrade: courseGrade)
                                        .tag(GradeQueryViewModel.SelectionItem(course: courseGrade.courseID))
                                }
                            } label: {
                                HStack {
                                    Text(group.semester)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text("\(group.grades.count)门课程")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("学期GPA: \(viewModel.semesterGPAs[group.semester] ?? 0.0, specifier: "%.2f")")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture { viewModel.toggleExpandSemester(group.semester) }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            } else {
                emptyStateSection.background(Color(.systemGroupedBackground))
            }
        }
        .safeAreaInset(edge: .top) {
            statsSection
                .padding(.horizontal)
                .padding(.vertical)
                .background(.ultraThinMaterial)

        }
        .searchable(text: $viewModel.searchText, prompt: "搜索课程")
        .toast(isPresenting: $viewModel.isShowingError) {
            AlertToast(type: .error(.red), title: "错误", subTitle: viewModel.errorMessage)
        }
        .toast(isPresenting: $viewModel.isShowingWarning) {
            AlertToast(displayMode: .banner(.slide), type: .systemImage("exclamationmark.triangle", .yellow), title: "警告", subTitle: viewModel.warningMessage)
        }
        .task { viewModel.task() }
        .toolbar {
            if viewModel.isSelectionMode {
                selectionToolbar()
            } else {
                mainToolbar()
            }
        }
        .sheet(isPresented: $viewModel.isShowingShareSheet) { ShareSheet(items: [viewModel.shareContent!]) }
        .navigationTitle("成绩查询")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, .constant(viewModel.isSelectionMode ? .active : .inactive))
        .trackView("GradeQuery")
    }

    // MARK: - Main Toolbar

    @ToolbarContentBuilder
    private func mainToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button(action: viewModel.enterSelectionMode) {
                    Label("选择", systemImage: "checkmark.circle")
                }
                .disabled(viewModel.isLoading || viewModel.data == nil)
                Button(action: viewModel.exportGradesAsCSV) {
                    Label("导出为CSV表格", systemImage: "doc.plaintext")
                }
                .disabled(viewModel.isLoading || viewModel.data == nil)
            } label: {
                Label("更多操作", systemImage: "ellipsis.circle")
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button(action: { viewModel.loadCourseGrades() }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.9, anchor: .center)
                } else {
                    Label("查询", systemImage: "arrow.clockwise")
                }
            }
            .disabled(viewModel.isLoading)
        }
    }

    // MARK: - Selection Toolbar

    @ToolbarContentBuilder
    private func selectionToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("取消") { viewModel.exitSelectionMode() }
        }

        ToolbarItem(placement: .primaryAction) {
            Button("全选") { viewModel.selectAll() }
        }

        ToolbarItem(placement: .primaryAction) {
            Button("全不选") { viewModel.selectNone() }
        }
    }
}
