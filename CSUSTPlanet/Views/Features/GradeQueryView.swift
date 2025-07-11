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
    
    init(authManager: AuthManager) {
        _viewModel = StateObject(wrappedValue: GradeQueryViewModel(eduHelper: authManager.eduHelper))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                filterSection
                
                if viewModel.isQuerying {
                    ProgressView()
                        .padding(.vertical, 40)
                } else if viewModel.courseGrades.isEmpty {
                    emptyStateView
                } else {
                    statsCard
                    gradeListSection
                }
            }
            .padding(.vertical)
        }
        .alert("错误", isPresented: $viewModel.isShowingError) {
            Button("确认", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .task {
            viewModel.loadAvailableSemesters()
        }
        .navigationTitle("成绩查询")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.getCourseGrades()
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isQuerying)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("筛选条件")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Divider()
            
            HStack {
                Text("学期")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                if viewModel.isSemestersLoading {
                    ProgressView("加载中...")
                } else {
                    Button(action: viewModel.loadAvailableSemesters) {
                        Label("刷新学期", systemImage: "arrow.clockwise")
                    }
                    Picker("学期", selection: $viewModel.selectedSemester) {
                        Text("全部学期").tag("")
                        ForEach(viewModel.availableSemesters, id: \.self) { semester in
                            Text(semester).tag(semester)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            HStack {
                Text("课程性质")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Picker("课程性质", selection: $viewModel.selectedCourseNature) {
                    Text("全部性质").tag(nil as CourseNature?)
                    ForEach(CourseNature.allCases, id: \.self) { nature in
                        Text(nature.rawValue).tag(nature as CourseNature?)
                    }
                }
                .pickerStyle(.menu)
            }
            
            HStack {
                Text("修读方式")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Picker("修读方式", selection: $viewModel.selectedStudyMode) {
                    ForEach(StudyMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)
            }
            
            HStack {
                Text("显示模式")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Picker("显示模式", selection: $viewModel.selectedDisplayMode) {
                    ForEach(DisplayMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var emptyStateView: some View {
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
        .padding(.vertical, 40)
        .padding(.horizontal)
    }
    
    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学业统计")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Divider()
            
            let stats = viewModel.calculateStats()
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("GPA")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f", stats.gpa))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("已修总学分")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", stats.totalCredits))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("平均成绩")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(stats.averageGrade)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(gradeColor(stats.averageGrade))
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
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var gradeListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("成绩记录")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ForEach(viewModel.courseGrades, id: \.courseID) { courseGrade in
                Divider()
                gradeCard(courseGrade: courseGrade)
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private func gradeCard(courseGrade: CourseGrade) -> some View {
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
                    .foregroundColor(gradeColor(courseGrade.grade))
            }
            .padding(.bottom, 8)
            
            InfoRow(icon: "graduationcap", iconColor: .blue, label: "修读方式", value: courseGrade.studyMode)
            
            HStack(spacing: 20) {
                InfoRow(icon: "number.square", iconColor: .green, label: "学分", value: String(format: "%.1f", courseGrade.credit))
                InfoRow(icon: "star.fill", iconColor: .orange, label: "绩点", value: String(format: "%.1f", courseGrade.gradePoint))
            }
            
            if !courseGrade.semester.isEmpty {
                InfoRow(icon: "calendar", iconColor: .purple, label: "学期", value: courseGrade.semester)
            }
        }
        .padding(.horizontal)
    }
    
    private func gradeColor(_ grade: Int) -> Color {
        switch grade {
        case 90 ... 100: return .green
        case 80..<90: return .blue
        case 60..<80: return .orange
        default: return .red
        }
    }
}

// 需要在 GradeQueryViewModel 中添加以下方法
extension GradeQueryViewModel {
    struct Stats {
        let gpa: Double
        let totalCredits: Double
        let averageGrade: Int
        let courseCount: Int
    }
    
    func calculateStats() -> Stats {
        let totalCredits = courseGrades.reduce(0) { $0 + $1.credit }
        let totalGradePoints = courseGrades.reduce(0) { $0 + $1.gradePoint * $1.credit }
        let gpa = totalCredits > 0 ? totalGradePoints / totalCredits : 0
        let totalGrades = courseGrades.reduce(0) { $0 + $1.grade }
        let averageGrade = courseGrades.isEmpty ? 0 : totalGrades / courseGrades.count
        
        return Stats(
            gpa: gpa,
            totalCredits: totalCredits,
            averageGrade: averageGrade,
            courseCount: courseGrades.count
        )
    }
}

#Preview {
    NavigationStack {
        GradeQueryView(authManager: AuthManager())
    }
}
