//
//  CoursesView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/14.
//

import CSUSTKit
import SwiftUI

struct CoursesView: View {
    @StateObject var viewModel: CoursesViewModel
    
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
    
    init(moocHelper: MoocHelper) {
        _viewModel = StateObject(wrappedValue: CoursesViewModel(moocHelper: moocHelper))
    }
    
    var body: some View {
        Form {
            if viewModel.isLoading {
                ProgressView("加载中...")
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .id(viewModel.loadingID)
            } else if viewModel.courses.isEmpty {
                emptyStateSection
            } else {
                courseListSection
            }
        }
        .alert("错误", isPresented: $viewModel.isShowingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .task {
            guard !viewModel.isLoaded else { return }
            viewModel.isLoaded = true
            viewModel.loadCourses()
        }
        .navigationTitle("课程列表")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: viewModel.loadCourses) {
                    Label("刷新课程列表", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
    }
    
    // MARK: - Form Sections
    
    private var emptyStateSection: some View {
        Section {
            VStack(spacing: 8) {
                Image(systemName: "book.closed")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
                
                Text("暂无课程信息")
                    .font(.headline)
                
                Text("没有找到任何课程信息")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
    
    private var courseListSection: some View {
        Section {
            ForEach(viewModel.courses, id: \.self) { course in
                NavigationLink(destination: CourseDetailView(moocHelper: viewModel.moocHelper, course: course)) {
                    courseCard(course: course)
                }
            }
        }
    }
    
    private func courseCard(course: MoocHelper.Course) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(course.name)
                .font(.headline)
                .lineLimit(1)
                .padding(.bottom, 8)
            
            InfoRow(icon: "number", iconColor: .blue, label: "课程编号", value: course.number)
            InfoRow(icon: "building.columns", iconColor: .green, label: "开课院系", value: course.department)
            InfoRow(icon: "person", iconColor: .purple, label: "授课教师", value: course.teacher)
        }
        .padding(.vertical, 8)
    }
}
