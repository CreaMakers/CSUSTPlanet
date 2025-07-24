//
//  GradeAnalysisViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/12.
//

import CSUSTKit
import Foundation
import SwiftData
import WidgetKit

@MainActor
class GradeAnalysisViewModel: ObservableObject {
    private var eduHelper: EduHelper

    @Published var isQuerying: Bool = false

    @Published var isShowingError: Bool = false
    @Published var errorMessage: String = ""

    @Published var gradeAnalysisData: GradeAnalysisData?
    @Published var weightedAverageGrade: Double?

    init(eduHelper: EduHelper) {
        self.eduHelper = eduHelper
    }

    func getCourseGrades() {
        isQuerying = true
        Task {
            defer {
                isQuerying = false
            }

            do {
                let courseGrades = try await eduHelper.courseService.getCourseGrades()
                let gradeAnalysisData = GradeAnalysisData.fromCourseGrades(courseGrades)

                let totalCredits = courseGrades.reduce(0) { $0 + $1.credit }
                weightedAverageGrade = courseGrades.reduce(0) { $0 + (Double($1.grade) * $1.credit) } / totalCredits
                self.gradeAnalysisData = gradeAnalysisData

                if !courseGrades.isEmpty {
                    let context = SharedModel.context

                    let analyses = try context.fetch(FetchDescriptor<GradeAnalysis>())
                    for analysis in analyses {
                        context.delete(analysis)
                    }
                    let gradeAnalysis = GradeAnalysis(data: gradeAnalysisData)
                    context.insert(gradeAnalysis)
                    try context.save()

                    WidgetCenter.shared.reloadTimelines(ofKind: "GradeAnalysisWidget")
                }
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }
}
