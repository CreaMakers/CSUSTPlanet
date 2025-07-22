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

    @Published var gradeAnalysisData: GradeAnalysisData = .empty()

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
                gradeAnalysisData = GradeAnalysisData.fromCourseGrades(courseGrades)

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
