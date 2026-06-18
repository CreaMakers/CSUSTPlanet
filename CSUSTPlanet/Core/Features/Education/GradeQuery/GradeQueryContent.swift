//
//  GradeQueryContent.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/18.
//

import CSUSTKit
import SwiftUI

struct GradeQueryContent: View {
    @Binding var searchText: String

    let groupedFilteredGrades: [(semester: String, grades: [EduHelper.CourseGrade])]
    let expandedSemesters: Set<String>
    let semesterGPAs: [String: Double]
    let gradeAnalysis: GradeAnalysisData?
    let gradeCount: Int

    let isLoadingGrades: Bool
    let areGradeActionsDisabled: Bool
    let isSelectionMode: Bool
    let selectedCourseIDs: Set<String>

    @Binding var errorToast: ToastState
    let shareContent: Any?
    @Binding var isShareSheetPresented: Bool

    let onRefreshGrades: () async -> Void
    let onToggleSemester: (String) -> Void
    let onEnterSelectionMode: () -> Void
    let onExitSelectionMode: () -> Void
    let onSelectAll: () -> Void
    let onSelectNone: () -> Void
    let onToggleSelection: (String) -> Void
    let onExportGrades: () -> Void

    var body: some View {
        Group {
            if !groupedFilteredGrades.isEmpty {
                GradeQuerySectionList(
                    groupedGrades: groupedFilteredGrades,
                    expandedSemesters: expandedSemesters,
                    semesterGPAs: semesterGPAs,
                    isSelectionMode: isSelectionMode,
                    selectedCourseIDs: selectedCourseIDs,
                    onToggleSemester: onToggleSemester,
                    onToggleSelection: onToggleSelection
                )
            } else if searchText.isEmpty {
                ContentUnavailableView("暂无成绩记录", systemImage: "doc.text.magnifyingglass", description: Text("没有找到成绩记录"))
            } else {
                ContentUnavailableView.search(text: searchText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .top) {
            GradeQueryStatsSection(analysis: gradeAnalysis, isLoadingGrades: isLoadingGrades)
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
            Button(action: onEnterSelectionMode) {
                Label("选择", systemImage: "checkmark.circle")
            }
            .disabled(areGradeActionsDisabled)

            Button(action: onExportGrades) {
                Label("导出表格", systemImage: "doc.plaintext")
            }
            .disabled(areGradeActionsDisabled)
        }

        ToolbarItem(placement: .primaryAction) {
            Button(asyncAction: onRefreshGrades) {
                if isLoadingGrades {
                    ProgressView().smallControlSizeOnMac()
                } else {
                    Label("查询", systemImage: "arrow.clockwise")
                }
            }
            .disabled(isLoadingGrades)
        }
    }

    @ToolbarContentBuilder
    private func selectionToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("取消", action: onExitSelectionMode)
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Button("全选", action: onSelectAll)
            Button("全不选", action: onSelectNone)
        }
    }
}

#Preview("GradeQueryContent") {
    @Previewable @State var searchText = ""
    @Previewable @State var errorToast = ToastState.errorTitle
    @Previewable @State var isShareSheetPresented = false

    NavigationStack {
        GradeQueryContent(
            searchText: $searchText,
            groupedFilteredGrades: GradeQueryPreviewData.groupedGrades,
            expandedSemesters: Set(GradeQueryPreviewData.grades.map { $0.semester }),
            semesterGPAs: GradeQueryPreviewData.semesterGPAs,
            gradeAnalysis: GradeAnalysisData.fromCourseGrades(GradeQueryPreviewData.grades),
            gradeCount: GradeQueryPreviewData.grades.count,
            isLoadingGrades: false,
            areGradeActionsDisabled: false,
            isSelectionMode: false,
            selectedCourseIDs: [],
            errorToast: $errorToast,
            shareContent: nil,
            isShareSheetPresented: $isShareSheetPresented,
            onRefreshGrades: {},
            onToggleSemester: { _ in },
            onEnterSelectionMode: {},
            onExitSelectionMode: {},
            onSelectAll: {},
            onSelectNone: {},
            onToggleSelection: { _ in },
            onExportGrades: {}
        )
    }
}

#Preview("GradeQueryContent Selection") {
    @Previewable @State var searchText = ""
    @Previewable @State var errorToast = ToastState.errorTitle
    @Previewable @State var isShareSheetPresented = false

    NavigationStack {
        GradeQueryContent(
            searchText: $searchText,
            groupedFilteredGrades: GradeQueryPreviewData.groupedGrades,
            expandedSemesters: Set(GradeQueryPreviewData.grades.map { $0.semester }),
            semesterGPAs: GradeQueryPreviewData.semesterGPAs,
            gradeAnalysis: GradeAnalysisData.fromCourseGrades([GradeQueryPreviewData.grades[0]]),
            gradeCount: GradeQueryPreviewData.grades.count,
            isLoadingGrades: false,
            areGradeActionsDisabled: false,
            isSelectionMode: true,
            selectedCourseIDs: [GradeQueryPreviewData.grades[0].courseID],
            errorToast: $errorToast,
            shareContent: nil,
            isShareSheetPresented: $isShareSheetPresented,
            onRefreshGrades: {},
            onToggleSemester: { _ in },
            onEnterSelectionMode: {},
            onExitSelectionMode: {},
            onSelectAll: {},
            onSelectNone: {},
            onToggleSelection: { _ in },
            onExportGrades: {}
        )
    }
}
