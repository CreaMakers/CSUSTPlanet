//
//  GradeDetailViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/12.
//

import CSUSTKit
import Foundation
import SwiftUI

@MainActor
class GradeDetailViewModel: ObservableObject {
    @Published var gradeDetail: EduHelper.GradeDetail?
    @Published var errorMessage: String = ""
    @Published var warningMessage: String = ""

    @Published var isLoading = false
    @Published var isShowingError = false
    @Published var isShowingWarning = false

    func task(_ courseGrade: EduHelper.CourseGrade) {
        loadDetail(courseGrade)
    }

    func loadDetail(_ courseGrade: EduHelper.CourseGrade) {
        isLoading = true

        Task {
            defer {
                isLoading = false
            }
            if let eduHelper = AuthManager.shared.eduHelper {
                do {
                    gradeDetail = try await eduHelper.courseService.getGradeDetail(url: courseGrade.gradeDetailUrl)
                } catch {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.warningMessage = "请先登录教务系统后再查询数据"
                    self.isShowingWarning = true
                }
            }
        }
    }
}
