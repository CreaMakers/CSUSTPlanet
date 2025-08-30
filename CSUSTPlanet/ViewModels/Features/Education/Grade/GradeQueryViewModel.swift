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
    @Published var courseGrades: [EduHelper.CourseGrade] = []
    @Published var stats: Stats? = nil

    @Published var isQuerying: Bool = false
    @Published var isSemestersLoading: Bool = false

    @Published var selectedSemester: String = ""
    @Published var selectedCourseNature: EduHelper.CourseNature? = nil
    @Published var selectedDisplayMode: EduHelper.DisplayMode = .bestGrade
    @Published var selectedStudyMode: EduHelper.StudyMode = .major

    @Published var isShowingError: Bool = false
    @Published var errorMessage: String = ""

    @Published var isShowingFilter: Bool = false
    @Published var searchText: String = ""

    var isLoaded: Bool = false

    var filteredCourseGrades: [EduHelper.CourseGrade] {
        if searchText.isEmpty {
            return courseGrades
        } else {
            return courseGrades.filter { $0.courseName.localizedCaseInsensitiveContains(searchText) }
        }
    }

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

    private func updateStats() {
        let totalCredits = courseGrades.reduce(0) { $0 + $1.credit }
        if courseGrades.isEmpty || totalCredits == 0 {
            stats = nil
            return
        }
        let totalGradePoints = courseGrades.reduce(0) { $0 + $1.gradePoint * $1.credit }
        let gpa = totalCredits > 0 ? totalGradePoints / totalCredits : 0
        let totalGrades = courseGrades.reduce(0) { $0 + $1.grade }
        let weightedAverageGrade = courseGrades.reduce(0) { $0 + Double($1.grade) * $1.credit } / totalCredits
        let averageGrade = courseGrades.isEmpty ? 0 : Double(totalGrades) / Double(courseGrades.count)

        stats = Stats(
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
        Task {
            defer {
                isQuerying = false
            }

            do {
                courseGrades = try await eduHelper.courseService.getCourseGrades(
                    academicYearSemester: selectedSemester,
                    courseNature: selectedCourseNature,
                    courseName: "",
                    displayMode: selectedDisplayMode,
                    studyMode: selectedStudyMode
                )
                self.updateStats()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }
}
