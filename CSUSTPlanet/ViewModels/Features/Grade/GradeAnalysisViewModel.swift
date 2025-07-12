//
//  GradeAnalysisViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/12.
//

import CSUSTKit
import Foundation

@MainActor
class GradeAnalysisViewModel: ObservableObject {
    private var eduHelper: EduHelper?

    @Published var isQuerying: Bool = false

    @Published var isShowingError: Bool = false
    @Published var errorMessage: String = ""

    @Published var courseGrades: [CourseGrade] = []

    init(eduHelper: EduHelper? = nil) {
        self.eduHelper = eduHelper
    }

    func getCourseGrades() {
        guard let eduHelper = eduHelper else {
            errorMessage = "教务服务未初始化"
            isShowingError = true
            return
        }

        isQuerying = true
        Task {
            defer {
                isQuerying = false
            }

            do {
                courseGrades = try await eduHelper.courseService.getCourseGrades()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }
}
