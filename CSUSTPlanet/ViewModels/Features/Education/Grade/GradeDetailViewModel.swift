//
//  GradeDetailViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/12.
//

import CSUSTKit
import Foundation

@MainActor
class GradeDetailViewModel: ObservableObject {
    private var eduHelper: EduHelper

    @Published var courseGrade: EduHelper.CourseGrade

    @Published var isLoadingDetail = false

    @Published var isShowingError = false
    @Published var errorMessage: String = ""

    @Published var gradeDetail: EduHelper.GradeDetail?

    init(eduHelper: EduHelper, courseGrade: EduHelper.CourseGrade) {
        self.eduHelper = eduHelper
        self.courseGrade = courseGrade
    }

    func loadDetail() {
        isLoadingDetail = true

        Task {
            defer {
                isLoadingDetail = false
            }

            do {
                gradeDetail = try await eduHelper.courseService.getGradeDetail(url: courseGrade.gradeDetailUrl)
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }
}
