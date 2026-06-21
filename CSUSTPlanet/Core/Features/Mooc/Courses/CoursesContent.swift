//
//  CoursesContent.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/21.
//

import CSUSTKit
import SwiftUI

struct CoursesContent: View {
    let courses: [MoocHelper.Course]

    @State private var searchText = ""

    let isLoading: Bool

    @Binding var errorToast: ToastState

    let onRefreshCourses: () async -> Void

    private var filteredCourses: [MoocHelper.Course] {
        guard !searchText.isEmpty else {
            return courses
        }

        return courses.filter { course in
            course.name.localizedCaseInsensitiveContains(searchText)
                || course.teacher?.localizedCaseInsensitiveContains(searchText) == true
                || course.department?.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    var body: some View {
        Group {
            if filteredCourses.isEmpty {
                if searchText.isEmpty {
                    ContentUnavailableView("暂无课程信息", systemImage: "book.closed", description: Text("没有找到任何课程信息"))
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            } else {
                CustomScrollView {
                    ForEach(filteredCourses, id: \.id) { course in
                        CustomGroupBox {
                            NavigationLink(value: AppRoute.features(.mooc(.courses(.detail(course))))) {
                                CoursesCourseRow(course: course)
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
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索课程")
        #elseif os(macOS)
        .searchable(text: $searchText, placement: .toolbar, prompt: "搜索课程")
        #endif
        #if os(iOS)
        .background(Color(PlatformColor.systemGroupedBackground))
        #endif
        .errorToast($errorToast)
        .safeRefreshable { await onRefreshCourses() }
        .navigationTitle("课程列表")
        .navigationSubtitleCompat("共\(courses.count)门课程")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(asyncAction: onRefreshCourses) {
                    if isLoading {
                        ProgressView().smallControlSizeOnMac()
                    } else {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(isLoading)
            }
        }
    }
}

#Preview("CoursesContent") {
    NavigationStack {
        CoursesContent(
            courses: MoocCoursesPreviewData.courses,
            isLoading: false,
            errorToast: .constant(.errorTitle),
            onRefreshCourses: {}
        )
    }
}

#Preview("CoursesContent Empty") {
    NavigationStack {
        CoursesContent(
            courses: [],
            isLoading: false,
            errorToast: .constant(.errorTitle),
            onRefreshCourses: {}
        )
    }
}
