//
//  GradeQueryViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import CSUSTKit
import Foundation

@MainActor
class GradeQueryViewModel: ObservableObject {
    private var eduHelper: EduHelper?

    @Published var availableSemesters: [String] = []
    @Published var selectedSemester: String = ""
    @Published var isSemestersLoading: Bool = false

    @Published var courseGrades: [CourseGrade] = []
    @Published var isQuerying: Bool = false

    @Published var selectedCourseNature: CourseNature? = nil
    @Published var selectedDisplayMode: DisplayMode = .bestGrade
    @Published var selectedStudyMode: StudyMode = .major

    @Published var courseName: String = ""

    @Published var isShowingError: Bool = false
    @Published var errorMessage: String = ""

    init(eduHelper: EduHelper? = nil) {
        self.eduHelper = eduHelper
    }

    func loadAvailableSemesters() {
        guard let eduHelper = eduHelper else {
            errorMessage = "教务服务未初始化"
            isShowingError = true
            return
        }

        isSemestersLoading = true
        Task {
            defer {
                isSemestersLoading = false
            }

            do {
                availableSemesters = try await eduHelper.courseService.getAvailableSemestersForCourseGrades()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
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
                courseGrades = try await eduHelper.courseService.getCourseGrades(
                    academicYearSemester: selectedSemester,
                    courseNature: selectedCourseNature,
                    courseName: courseName,
                    displayMode: selectedDisplayMode,
                    studyMode: selectedStudyMode
                )
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }
}
