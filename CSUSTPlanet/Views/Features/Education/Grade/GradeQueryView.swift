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
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject var viewModel: GradeQueryViewModel
    
    private var eduHelper: EduHelper
    
    init(eduHelper: EduHelper) {
        _viewModel = StateObject(wrappedValue: GradeQueryViewModel(eduHelper: eduHelper))
        self.eduHelper = eduHelper
    }
    
    // MARK: - Stat Item
    
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

    private var statsSection: some View {
        VStack(alignment: .center) {
            HStack(spacing: 10) {
                if let stats = viewModel.stats {
                    statItem(title: "GPA", value: String(format: "%.2f", stats.gpa), color: ColorHelper.dynamicColor(point: stats.gpa))
                    statItem(title: "平均成绩", value: String(format: "%.2f", stats.averageGrade), color: ColorHelper.dynamicColor(grade: stats.averageGrade))
                    statItem(title: "加权平均成绩", value: String(format: "%.2f", stats.weightedAverageGrade), color: ColorHelper.dynamicColor(grade: stats.weightedAverageGrade))
                    statItem(title: "已修总学分", value: String(format: "%.1f", stats.totalCredits), color: .blue)
                    statItem(title: "课程总数", value: "\(stats.courseCount)", color: .purple)
                } else {
                    // Placeholder items for initial redacted state
                    statItem(title: "GPA", value: "0.0", color: .primary)
                    statItem(title: "平均成绩", value: "0.0", color: .primary)
                    statItem(title: "加权平均成绩", value: "0.0", color: .primary)
                    statItem(title: "已修总学分", value: "0.0", color: .primary)
                    statItem(title: "课程总数", value: "0", color: .primary)
                }
            }
            .frame(maxWidth: .infinity)
            .redacted(reason: viewModel.isQuerying ? .placeholder : [])
        }
    }
    
    // MARK: - Filter View
    
    private var filterView: some View {
        NavigationStack {
            Form {
                Section(header: Text("学期选择")) {
                    if viewModel.isSemestersLoading {
                        HStack {
                            Text("学期")
                            Spacer()
                            ProgressView()
                        }
                    } else {
                        Picker("学期", selection: $viewModel.selectedSemester) {
                            Text("全部学期").tag("")
                            ForEach(viewModel.availableSemesters, id: \.self) { semester in
                                Text(semester).tag(semester)
                            }
                        }
                        .pickerStyle(.wheel)
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
            .navigationTitle("筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
//                    Button {
//                        viewModel.loadAvailableSemesters()
//                    } label: {
//                        Label("刷新可选学期列表", systemImage: "arrow.clockwise")
//                    }
//                    .disabled(viewModel.isSemestersLoading)
                    Button("取消") {
                        viewModel.isShowingFilter = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        viewModel.isShowingFilter = false
                        viewModel.getCourseGrades()
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State Section
    
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
                            .foregroundColor(ColorHelper.dynamicColor(point: courseGrade.gradePoint))
                    }
                }
            }
            
            Spacer()
            
            Text("\(courseGrade.grade)分")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(ColorHelper.dynamicColor(grade: Double(courseGrade.grade)))
        }
        .padding(.vertical, 8)
    }

    private func gradeCard(courseGrade: EduHelper.CourseGrade) -> some View {
        NavigationLink(destination: GradeDetailView(eduHelper: eduHelper, courseGrade: courseGrade)) {
            gradeCardContent(courseGrade: courseGrade)
        }
    }

    // MARK: - Shareable View

    private var shareableView: some View {
        VStack(spacing: 0) {
            statsSection
                .padding(.horizontal)
                .padding(.vertical)

            Divider()

            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.filteredCourseGrades, id: \.courseID) { courseGrade in
                    gradeCardContent(courseGrade: courseGrade)
                        .padding(.horizontal)
                    Divider()
                }
            }
        }
        .padding(.vertical)
        .frame(width: UIScreen.main.bounds.width)
        .background(Color(.systemGroupedBackground))
        .environment(\.colorScheme, colorScheme)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            statsSection
                .padding(.horizontal)
                .padding(.vertical)
                .background(Color(.secondarySystemBackground))

            if viewModel.isQuerying {
                ProgressView("正在查询...")
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
            } else if viewModel.filteredCourseGrades.isEmpty {
                emptyStateSection
                    .background(Color(.systemGroupedBackground))
            } else {
                List {
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
        .toast(isPresenting: $viewModel.isShowingSuccess) {
            AlertToast(type: .complete(.green), title: "图片保存成功")
        }
        .task { viewModel.task() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { viewModel.isShowingFilter.toggle() }) {
                        Label("筛选", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    Button(action: { viewModel.showShareSheet(shareableView) }) {
                        Label("分享", systemImage: "square.and.arrow.up")
                    }
                    .disabled(viewModel.isQuerying)
                    Button(action: { viewModel.saveToPhotoAlbum(shareableView) }) {
                        Label("保存结果到相册", systemImage: "photo")
                    }
                    .disabled(viewModel.isQuerying)
                } label: {
                    Label("更多操作", systemImage: "ellipsis.circle")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: viewModel.getCourseGrades) {
                    Label("查询", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isQuerying)
            }
        }
        .sheet(isPresented: $viewModel.isShowingShareSheet) { ShareSheet(items: [viewModel.shareContent!]) }
        .popover(isPresented: $viewModel.isShowingFilter) { filterView }
        .navigationTitle("成绩查询")
        .navigationBarTitleDisplayMode(.inline)
    }
}
