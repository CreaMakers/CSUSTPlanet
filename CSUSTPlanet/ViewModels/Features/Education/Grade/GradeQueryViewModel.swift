//
//  GradeQueryViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import CSUSTKit
import Foundation
import SwiftUI

@MainActor
class GradeQueryViewModel: ObservableObject {
    private var eduHelper: EduHelper

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

    @Published var queryID = UUID()

    @Published var isLoaded: Bool = false

    init(eduHelper: EduHelper) {
        self.eduHelper = eduHelper
    }

    struct Stats {
        let gpa: Double
        let totalCredits: Double
        let weightedAverageGrade: Double
        let averageGrade: Double
        let courseCount: Int
    }

    func calculateStats() -> Stats {
        let totalCredits = courseGrades.reduce(0) { $0 + $1.credit }
        let totalGradePoints = courseGrades.reduce(0) { $0 + $1.gradePoint * $1.credit }
        let gpa = totalCredits > 0 ? totalGradePoints / totalCredits : 0
        let totalGrades = courseGrades.reduce(0) { $0 + $1.grade }
        let weightedAverageGrade = courseGrades.reduce(0) { $0 + Double($1.grade) * $1.credit } / totalCredits
        let averageGrade = courseGrades.isEmpty ? 0 : Double(totalGrades) / Double(courseGrades.count)

        return Stats(
            gpa: gpa,
            totalCredits: totalCredits,
            weightedAverageGrade: weightedAverageGrade,
            averageGrade: averageGrade,
            courseCount: courseGrades.count
        )
    }

    func loadAvailableSemesters() {
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
        isQuerying = true
        queryID = UUID()
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
