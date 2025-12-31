//
//  CoursesView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/14.
//

import CSUSTKit
import SwiftUI

struct CoursesView: View {
    @StateObject var viewModel = CoursesViewModel()

    var body: some View {
        Form {
            if viewModel.isLoading {
                ProgressView("加载中...")
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if viewModel.filteredCourses.isEmpty {
                emptyStateSection
            } else {
                courseListSection
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "搜索课程")
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
        .trackView("Courses")
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

                Text(viewModel.searchText.isEmpty ? "没有找到任何课程信息" : "没有找到匹配的课程")
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
            ForEach(viewModel.filteredCourses, id: \.self) { course in
                TrackLink(destination: CourseDetailView(course: course)) {
                    courseCard(course: course)
                }
            }
        }
    }

    private func courseCard(course: MoocHelper.Course) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(course.name)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(spacing: 12) {
                infoItem(icon: "person.fill", color: .purple, text: course.teacher)
                infoItem(icon: "building.columns.fill", color: .green, text: course.department)
            }
        }
        .padding(.vertical, 6)
    }

    private func infoItem(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .imageScale(.small)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}
