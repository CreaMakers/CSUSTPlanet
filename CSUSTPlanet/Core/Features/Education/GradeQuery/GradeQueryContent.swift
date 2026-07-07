//
//  GradeQueryContent.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/18.
//

import CSUSTKit
import SwiftUI

struct GradeQueryContent: View {
    let grades: [EduHelper.CourseGrade]?

    private var filteredGrades: [EduHelper.CourseGrade] {
        if searchText.isEmpty {
            return grades ?? []
        }
        return grades?.filter { $0.courseName.localizedCaseInsensitiveContains(searchText) } ?? []
    }

    private var groupedFilteredGrades: [(semester: String, grades: [EduHelper.CourseGrade])] {
        let grouped = Dictionary(grouping: filteredGrades) { $0.semester }
        return grouped.keys.sorted(by: >).map { (semester: $0, grades: grouped[$0] ?? []) }
    }

    private var gradeAnalysis: GradeAnalysisData? {
        guard let grades else { return nil }

        if isSelectionMode {
            return GradeAnalysisData.fromCourseGrades(grades.filter { selectedCourseIDs.contains($0.courseID) })
        }
        return GradeAnalysisData.fromCourseGrades(grades)
    }

    private var semesterGPAs: [String: Double] {
        Dictionary(grouping: grades ?? [], by: { $0.semester }).reduce(into: [:]) { result, entry in
            let totalCredits = entry.value.reduce(0) { $0 + $1.credit }
            let totalGradePoints = entry.value.reduce(0) { $0 + $1.gradePoint * $1.credit }
            result[entry.key] = totalCredits > 0 ? totalGradePoints / totalCredits : 0.0
        }
    }

    private var gradeCount: Int {
        grades?.count ?? 0
    }

    @Binding var searchText: String

    @Binding var isSelectionMode: Bool
    @Binding var selectedCourseIDs: Set<String>

    let isLoading: Bool

    @Binding var errorToast: ToastState

    let shareContent: Any?
    @Binding var isShareSheetPresented: Bool

    let onRefreshGrades: () async -> Void
    let onExportGrades: () -> Void

    var body: some View {
        Group {
            if !groupedFilteredGrades.isEmpty {
                CustomScrollView {
                    ForEach(groupedFilteredGrades, id: \.semester) { group in
                        GradeQuerySection(
                            semester: group.semester,
                            grades: group.grades,
                            semesterGPA: semesterGPAs[group.semester] ?? 0.0,
                            isSelectionMode: isSelectionMode,
                            selectedCourseIDs: $selectedCourseIDs
                        )
                    }
                    .padding()
                }
            } else if searchText.isEmpty {
                ContentUnavailableView("暂无成绩记录", systemImage: "doc.text.magnifyingglass", description: Text("没有找到成绩记录"))
            } else {
                ContentUnavailableView.search(text: searchText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .top) {
            GradeQueryStatsSection(analysis: gradeAnalysis, isLoading: isLoading)
                .frame(maxWidth: 700)
        }
        #if os(iOS)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索课程")
        #elseif os(macOS)
        .searchable(text: $searchText, placement: .toolbar, prompt: "搜索课程")
        #endif
        .safeRefreshable { await onRefreshGrades() }
        .errorToast($errorToast)
        .toolbar {
            if isSelectionMode {
                selectionToolbar()
            } else {
                mainToolbar()
            }
        }
        #if os(iOS)
        .sheet(isPresented: $isShareSheetPresented) {
            ShareSheet(items: [shareContent ?? "分享错误"])
        }
        #endif
        .navigationTitle("成绩查询")
        .navigationSubtitleCompat("共\(gradeCount)门课程成绩")
        .inlineToolbarTitle()
    }

    @ToolbarContentBuilder
    private func mainToolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .secondaryAction) {
            Button(action: {
                selectedCourseIDs = filteredCourseIDs
                isSelectionMode = true
            }) {
                Label("选择", systemImage: "checkmark.circle")
            }
            .disabled(isLoading)

            Button(action: onExportGrades) {
                Label("导出表格", systemImage: "doc.plaintext")
            }
            .disabled(isLoading)
        }

        ToolbarItem(placement: .primaryAction) {
            Button(asyncAction: onRefreshGrades) {
                if isLoading {
                    ProgressView().smallControlSizeOnMac()
                } else {
                    Label("查询", systemImage: "arrow.clockwise")
                }
            }
            .disabled(isLoading)
        }
    }

    @ToolbarContentBuilder
    private func selectionToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("取消") {
                isSelectionMode = false
                selectedCourseIDs.removeAll()
            }
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Button("全选") {
                selectedCourseIDs = filteredCourseIDs
            }
            Button("全不选") {
                selectedCourseIDs.removeAll()
            }
        }
    }

    private var filteredCourseIDs: Set<String> {
        Set(
            groupedFilteredGrades.flatMap { group in
                group.grades.map(\.courseID)
            })
    }
}

#Preview("GradeQueryContent") {
    @Previewable @State var searchText = ""
    @Previewable @State var isSelectionMode = false
    @Previewable @State var selectedCourseIDs: Set<String> = []
    @Previewable @State var errorToast = ToastState.errorTitle
    @Previewable @State var isShareSheetPresented = false

    NavigationStack {
        GradeQueryContent(
            grades: GradeQueryPreviewData.grades,
            searchText: $searchText,
            isSelectionMode: $isSelectionMode,
            selectedCourseIDs: $selectedCourseIDs,
            isLoading: false,
            errorToast: $errorToast,
            shareContent: nil,
            isShareSheetPresented: $isShareSheetPresented,
            onRefreshGrades: {},
            onExportGrades: {}
        )
    }
}

#Preview("GradeQueryContent Selection") {
    @Previewable @State var searchText = ""
    @Previewable @State var isSelectionMode = true
    @Previewable @State var selectedCourseIDs: Set<String> = [GradeQueryPreviewData.grades[0].courseID]
    @Previewable @State var errorToast = ToastState.errorTitle
    @Previewable @State var isShareSheetPresented = false

    NavigationStack {
        GradeQueryContent(
            grades: GradeQueryPreviewData.grades,
            searchText: $searchText,
            isSelectionMode: $isSelectionMode,
            selectedCourseIDs: $selectedCourseIDs,
            isLoading: false,
            errorToast: $errorToast,
            shareContent: nil,
            isShareSheetPresented: $isShareSheetPresented,
            onRefreshGrades: {},
            onExportGrades: {}
        )
    }
}
