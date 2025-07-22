//
//  GradeQueryView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import CSUSTKit
import SwiftUI

struct GradeQueryView: View {
    @StateObject var viewModel: GradeQueryViewModel
    
    private var eduHelper: EduHelper
    
    struct InfoRow: View {
        let icon: String
        let iconColor: Color
        let label: String
        let value: String
        
        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
    
    init(eduHelper: EduHelper) {
        _viewModel = StateObject(wrappedValue: GradeQueryViewModel(eduHelper: eduHelper))
        self.eduHelper = eduHelper
    }
    
    var body: some View {
        Form {
            filterSection
            
            if viewModel.isQuerying {
                ProgressView("正在查询...")
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .id(viewModel.queryID)
            } else if viewModel.courseGrades.isEmpty {
                emptyStateSection
            } else {
                statsSection
                gradeListSection
            }
        }
        .alert("错误", isPresented: $viewModel.isShowingError) {
            Button("确认", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .task {
            guard !viewModel.isLoaded else { return }
            viewModel.isLoaded = true
            viewModel.loadAvailableSemesters()
            viewModel.getCourseGrades()
        }
        .navigationTitle("成绩查询")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        viewModel.loadAvailableSemesters()
                    } label: {
                        Label("刷新可选学期列表", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isSemestersLoading)
                    Button {
                        viewModel.getCourseGrades()
                    } label: {
                        Label("查询", systemImage: "magnifyingglass")
                    }
                    .disabled(viewModel.isQuerying)
                } label: {
                    Label("操作", systemImage: "ellipsis.circle")
                }
            }
        }
    }
    
    // MARK: - Form Sections
    
    private var filterSection: some View {
        Section(header: Text("筛选条件")) {
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
            }
            
            Picker("课程性质", selection: $viewModel.selectedCourseNature) {
                Text("全部性质").tag(nil as CourseNature?)
                ForEach(CourseNature.allCases, id: \.self) { nature in
                    Text(nature.rawValue).tag(nature as CourseNature?)
                }
            }
            
            Picker("修读方式", selection: $viewModel.selectedStudyMode) {
                ForEach(StudyMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            
            Picker("显示模式", selection: $viewModel.selectedDisplayMode) {
                ForEach(DisplayMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
        }
    }
    
    private var emptyStateSection: some View {
        Section {
            VStack(spacing: 8) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
                
                Text("暂无成绩记录")
                    .font(.headline)
                
                Text("当前筛选条件下没有找到成绩记录")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
    
    private var statsSection: some View {
        Section(header: Text("学业统计")) {
            let stats = viewModel.calculateStats()
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("GPA")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f", stats.gpa))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ColorHelper.dynamicColor(point: stats.gpa))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("平均成绩")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f", stats.averageGrade))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ColorHelper.dynamicColor(grade: stats.averageGrade))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("已修总学分")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", stats.totalCredits))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("课程总数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(stats.courseCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
    
    private var gradeListSection: some View {
        Section(header: Text("成绩记录")) {
            ForEach(viewModel.courseGrades, id: \.courseID) { courseGrade in
                gradeCard(courseGrade: courseGrade)
            }
        }
    }
    
    private func gradeCard(courseGrade: CourseGrade) -> some View {
        NavigationLink(destination: GradeDetailView(eduHelper: eduHelper, courseGrade: courseGrade)) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(courseGrade.courseName)
                        .font(.headline)
                    if !courseGrade.groupName.isEmpty {
                        Text("(\(courseGrade.groupName))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(courseGrade.grade)分")
                        .font(.headline)
                        .foregroundColor(ColorHelper.dynamicColor(grade: Double(courseGrade.grade)))
                }
                .padding(.bottom, 8)
                
                InfoRow(icon: "graduationcap", iconColor: .blue, label: "修读方式", value: courseGrade.studyMode)
                
                HStack(spacing: 20) {
                    InfoRow(icon: "number.square", iconColor: .green, label: "学分", value: String(format: "%.1f", courseGrade.credit))
                    InfoRow(icon: "star.fill", iconColor: .orange, label: "绩点", value: String(format: "%.1f", courseGrade.gradePoint)).foregroundColor(ColorHelper.dynamicColor(point: courseGrade.gradePoint))
                }
                
                if !courseGrade.semester.isEmpty {
                    InfoRow(icon: "calendar", iconColor: .purple, label: "学期", value: courseGrade.semester)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
