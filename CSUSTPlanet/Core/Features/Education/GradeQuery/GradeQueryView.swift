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

    // MARK: - Filter View

    @ViewBuilder
    private var filterView: some View {
        NavigationStack {
            Form {
                Section(header: Text("学期选择")) {
                    Picker("学期", selection: $viewModel.selectedSemester) {
                        Text("全部学期").tag("")
                        ForEach(viewModel.availableSemesters, id: \.self) { semester in
                            Text(semester).tag(semester)
                        }
                    }
                    .pickerStyle(.wheel)
                    HStack {
                        Button(action: viewModel.loadAvailableSemesters) {
                            Text("刷新学期列表")
                        }
                        if viewModel.isSemestersLoading {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                Section(header: Text("筛选条件")) {
                    Picker("课程性质", selection: $viewModel.selectedCourseNature) {
                        Text("全部性质").tag(nil as EduHelper.CourseNature?)
                        ForEach(EduHelper.CourseNature.allCases, id: \.self) { nature in
                            Text(nature.rawValue).tag(nature as EduHelper.CourseNature?)
                        }
                    }
                    Picker("修读方式", selection: $viewModel.selectedStudyMode) {
                        ForEach(EduHelper.StudyMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    Picker("显示模式", selection: $viewModel.selectedDisplayMode) {
                        ForEach(EduHelper.DisplayMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                }
            }
            .navigationTitle("高级查询")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        viewModel.isShowingFilterSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        viewModel.isShowingFilterSheet = false
                        viewModel.loadCourseGrades()
                    }
                }
            }
        }
    }

    // MARK: - Empty State Section

    @ViewBuilder
    private var emptyStateSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
                .padding(.bottom, 8)

            Text("暂无成绩记录")
                .font(.headline)

            Text(viewModel.searchText.isEmpty ? "当前筛选条件下没有找到成绩记录" : "没有找到匹配的课程")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 20)
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
        NavigationLink(destination: GradeDetailView(courseGrade: courseGrade)) {
            gradeCardContent(courseGrade: courseGrade)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            statsSection
                .padding(.horizontal)
                .padding(.vertical)
                .background(colorScheme == .light ? Color(.systemBackground) : Color(.secondarySystemBackground))

            if viewModel.data == nil {
                emptyStateSection
                    .background(Color(.systemGroupedBackground))
            } else {
                List(selection: $viewModel.selectedCourseIDs) {
                    ForEach(viewModel.filteredCourseGrades, id: \.courseID) { courseGrade in
                        gradeCard(courseGrade: courseGrade)
                    }
                }
                .listStyle(.insetGrouped)
            }
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
        .sheet(isPresented: $viewModel.isShowingFilterSheet) { filterView }
        .navigationTitle("成绩查询")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, .constant(viewModel.isSelectionMode ? .active : .inactive))
    }

    // MARK: - Main Toolbar

    @ToolbarContentBuilder
    private func mainToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button(action: {
                    viewModel.enterSelectionMode()
                }) {
                    Label("选择", systemImage: "checkmark.circle")
                }
                .disabled(viewModel.isLoading || viewModel.data == nil)

                Button(action: { viewModel.isShowingFilterSheet.toggle() }) {
                    Label("高级查询", systemImage: "slider.horizontal.3")
                }

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
            Button("取消") {
                viewModel.exitSelectionMode()
            }
        }

        ToolbarItem(placement: .primaryAction) {
            Button("全选") {
                viewModel.selectedCourseIDs = Set(viewModel.filteredCourseGrades.map { $0.courseID })
            }
        }

        ToolbarItem(placement: .primaryAction) {
            Button("全不选") {
                viewModel.selectedCourseIDs.removeAll()
            }
        }
    }
}
