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
    @State var viewModel = GradeQueryViewModel()

    // MARK: - Body

    var body: some View {
        Group {
            if !viewModel.filteredGrades.isEmpty {
                CustomScrollView {
                    ForEach(viewModel.groupedFilteredGrades, id: \.semester) { group in
                        CustomGroupBox {
                            let isExpanded = viewModel.expandedSemesters.contains(group.semester)

                            VStack {
                                HStack {
                                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                        .frame(width: 16, alignment: .leading)

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
                                .contentShape(.rect)
                                .onTapGesture { viewModel.toggleExpandSemester(group.semester) }

                                if isExpanded {
                                    ForEach(group.grades, id: \.courseID) { courseGrade in
                                        Divider()
                                        gradeCard(courseGrade: courseGrade)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                if viewModel.searchText.isEmpty {
                    ContentUnavailableView("暂无成绩记录", systemImage: "doc.text.magnifyingglass", description: Text("没有找到成绩记录"))
                } else {
                    ContentUnavailableView.search(text: viewModel.searchText)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .top) {
            statsSection
                .padding(.horizontal)
                .padding(.vertical)
                .apply { view in
                    if #available(iOS 26.0, macOS 26.0, *) {
                        view
                            .glassEffect()
                            .padding(.horizontal)
                    } else {
                        view.background(.ultraThinMaterial)
                    }
                }
                .frame(maxWidth: 700)
        }
        #if os(iOS)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索课程")
        #elseif os(macOS)
        .searchable(text: $viewModel.searchText, placement: .toolbar, prompt: "搜索课程")
        #endif
        .safeRefreshable { await viewModel.loadCourseGrades() }
        .errorToast($viewModel.errorToast)
        .task { await viewModel.loadInitial() }
        .toolbar {
            if viewModel.isSelectionMode {
                selectionToolbar()
            } else {
                mainToolbar()
            }
        }
        #if os(iOS)
        .sheet(isPresented: $viewModel.isShareSheetPresented) { ShareSheet(items: [viewModel.shareContent ?? "分享错误"]) }
        #endif
        .navigationTitle("成绩查询")
        .navigationSubtitleCompat("共\(viewModel.gradeData?.value.count ?? 0)门课程成绩")
        .inlineToolbarTitle()
    }

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
            if let analysis = viewModel.gradeAnalysis {
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
                .redacted(reason: viewModel.isLoadingGrades ? .placeholder : [])
            }
        }
    }

    // MARK: - Grade Card Content

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
        .padding(.horizontal, 8)
    }

    // MARK: - Grade Card

    @ViewBuilder
    private func gradeCard(courseGrade: EduHelper.CourseGrade) -> some View {
        if viewModel.isSelectionMode {
            Button {
                viewModel.toggleSelection(for: courseGrade.courseID)
            } label: {
                gradeCardContent(courseGrade: courseGrade)
                    .contentShape(.rect)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(viewModel.isSelected(courseGrade.courseID) ? Color.gray.opacity(0.2) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: AppRoute.features(.education(.gradeQuery(.detail(courseGrade))))) {
                gradeCardContent(courseGrade: courseGrade)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Main Toolbar

    @ToolbarContentBuilder
    private func mainToolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .secondaryAction) {
            Button(action: viewModel.enterSelectionMode) {
                Label("选择", systemImage: "checkmark.circle")
            }
            .disabled(viewModel.isLoadingGrades || viewModel.gradeData?.value.isEmpty == true)
            Button(action: viewModel.exportGradesAsCSV) {
                Label("导出表格", systemImage: "doc.plaintext")
            }
            .disabled(viewModel.isLoadingGrades || viewModel.gradeData?.value.isEmpty == true)
        }
        ToolbarItem(placement: .primaryAction) {
            Button(asyncAction: viewModel.loadCourseGrades) {
                if viewModel.isLoadingGrades {
                    ProgressView().smallControlSizeOnMac()
                } else {
                    Label("查询", systemImage: "arrow.clockwise")
                }
            }
            .disabled(viewModel.isLoadingGrades)
        }
    }

    // MARK: - Selection Toolbar

    @ToolbarContentBuilder
    private func selectionToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("取消") { viewModel.exitSelectionMode() }
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Button("全选") { viewModel.selectAll() }
            Button("全不选") { viewModel.selectNone() }
        }
    }
}
