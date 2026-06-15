//
//  CoursesView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/14.
//

import CSUSTKit
import SwiftUI

struct CoursesView: View {
    @State var viewModel = CoursesViewModel()

    var body: some View {
        Group {
            if viewModel.filteredCourses.isEmpty {
                if viewModel.searchText.isEmpty {
                    ContentUnavailableView("暂无课程信息", systemImage: "book.closed", description: Text("没有找到任何课程信息"))
                } else {
                    ContentUnavailableView.search(text: viewModel.searchText)
                }
            } else {
                CustomScrollView {
                    ForEach(viewModel.filteredCourses, id: \.self) { course in
                        CustomGroupBox {
                            NavigationLink(value: AppRoute.features(.mooc(.courses(.detail(course))))) {
                                courseRow(course: course)
                                    .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        #if os(iOS)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索课程")
        #elseif os(macOS)
        .searchable(text: $viewModel.searchText, placement: .toolbar, prompt: "搜索课程")
        #endif
        #if os(iOS)
        .background(Color(PlatformColor.systemGroupedBackground))
        #endif
        .errorToast($viewModel.errorToast)
        .task { await viewModel.loadInitial() }
        .safeRefreshable { await viewModel.loadCourses() }
        .navigationTitle("课程列表")
        .navigationSubtitleCompat("共\(viewModel.courses.count)门课程")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(asyncAction: viewModel.loadCourses) {
                    if viewModel.isLoadingCourses {
                        ProgressView().smallControlSizeOnMac()
                    } else {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(viewModel.isLoadingCourses)
            }
        }
    }

    @ViewBuilder
    private func courseRow(course: MoocHelper.Course) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(course.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let teacher = course.teacher, let department = course.department {
                    HStack(spacing: 12) {
                        infoItem(icon: "person.fill", color: .purple, text: teacher)
                        infoItem(icon: "building.columns.fill", color: .green, text: department)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right").frame(width: 16)
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
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
