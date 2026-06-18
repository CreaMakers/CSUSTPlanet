//
//  GradeDetailView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/12.
//

import CSUSTKit
import SwiftUI

struct GradeDetailView: View {
    let courseGrade: EduHelper.CourseGrade

    @State private var renderMode: GradeDetailRenderMode = .progress
    @State private var detail: EduHelper.GradeDetail?
    @State private var isLoadingDetail = false
    @State private var errorToast: ToastState = .errorTitle

    var body: some View {
        GradeDetailContent(
            courseGrade: courseGrade,
            detail: detail,
            renderMode: $renderMode,
            isLoadingDetail: isLoadingDetail,
            errorToast: $errorToast,
            onRefresh: loadDetail
        )
        .task {
            await loadDetail()
        }
    }

    // MARK: - Data

    private func loadDetail() async {
        guard !isLoadingDetail else { return }
        isLoadingDetail = true
        defer { isLoadingDetail = false }

        let maxRetryCount = 5

        for _ in 1...maxRetryCount {
            do {
                let gradeDetail = try await AuthManager.shared.withAuthRetry(system: .edu) {
                    try await AuthManager.shared.eduHelper.courseService.getGradeDetail(url: courseGrade.gradeDetailUrl)
                }

                detail = gradeDetail
                return
            } catch {}
        }

        errorToast.show(message: "获取成绩详情失败，请刷新重试")
    }
}
