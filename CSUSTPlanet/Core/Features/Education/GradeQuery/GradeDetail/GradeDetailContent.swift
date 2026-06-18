//
//  GradeDetailContent.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/18.
//

import CSUSTKit
import SwiftUI

enum GradeDetailRenderMode: String, CaseIterable, Identifiable {
    case pie = "饼图"
    case progress = "进度条"

    var id: String { rawValue }
}

struct GradeDetailContent: View {
    let courseGrade: EduHelper.CourseGrade
    let detail: EduHelper.GradeDetail?

    @Binding var renderMode: GradeDetailRenderMode
    let isLoadingDetail: Bool

    @Binding var errorToast: ToastState

    let onRefresh: () async -> Void

    var body: some View {
        CustomScrollView {
            VStack(alignment: .leading, spacing: 24) {
                GradeDetailScoreSummary(courseGrade: courseGrade)
                GradeDetailDistributionSection(detail: detail, renderMode: $renderMode)
                GradeDetailInfoSection(courseGrade: courseGrade)
            }
            .padding()
        }
        .safeRefreshable { await onRefresh() }
        .errorToast($errorToast)
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(asyncAction: onRefresh) {
                    if isLoadingDetail {
                        ProgressView().smallControlSizeOnMac()
                    } else {
                        Label("刷新成绩分布", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

#Preview("GradeDetailContent Progress") {
    @Previewable @State var renderMode = GradeDetailRenderMode.progress
    @Previewable @State var errorToast = ToastState.errorTitle

    NavigationStack {
        GradeDetailContent(
            courseGrade: GradeQueryPreviewData.grades[0],
            detail: GradeQueryPreviewData.detail,
            renderMode: $renderMode,
            isLoadingDetail: false,
            errorToast: $errorToast,
            onRefresh: {}
        )
    }
}

#Preview("GradeDetailContent Pie") {
    @Previewable @State var renderMode = GradeDetailRenderMode.pie
    @Previewable @State var errorToast = ToastState.errorTitle

    NavigationStack {
        GradeDetailContent(
            courseGrade: GradeQueryPreviewData.grades[0],
            detail: GradeQueryPreviewData.detail,
            renderMode: $renderMode,
            isLoadingDetail: false,
            errorToast: $errorToast,
            onRefresh: {}
        )
    }
}
