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
    private var eduHelper: EduHelper

    @Published var isQuerying: Bool = false

    @Published var isShowingError: Bool = false
    @Published var errorMessage: String = ""

    @Published var courseGrades: [CourseGrade] = []

    var semesterAverageGrades: [(semester: String, average: Double)] {
        Dictionary(grouping: courseGrades, by: { $0.semester })
            .map { semester, grades in
                let average = Double(grades.reduce(0) { $0 + $1.grade }) / Double(grades.count)
                return (semester: semester, average: average)
            }
            .sorted { $0.semester < $1.semester }
    }

    var semesterGPAs: [(semester: String, gpa: Double)] {
        Dictionary(grouping: courseGrades, by: { $0.semester })
            .map { semester, grades in
                let (totalPoints, totalCredits) = grades.reduce((0.0, 0.0)) { result, grade in
                    (result.0 + grade.gradePoint * grade.credit, result.1 + grade.credit)
                }
                let gpa = totalCredits > 0 ? totalPoints / totalCredits : 0.0
                return (semester: semester, gpa: gpa)
            }
            .sorted { $0.semester < $1.semester }
    }

    var gradePointDistribution: [(gradePoint: Double, count: Int)] {
        let gradePointGroups = courseGrades.reduce(into: [Double: Int]()) { dict, grade in
            dict[grade.gradePoint, default: 0] += 1
        }

        return gradePointGroups
            .map { (gradePoint: $0.key, count: $0.value) }
            .filter { $0.count > 0 }
            .sorted { $0.gradePoint > $1.gradePoint }
    }

    var overallAverageGrade: Double {
        guard !courseGrades.isEmpty else { return 0.0 }
        return Double(courseGrades.reduce(0) { $0 + $1.grade }) / Double(courseGrades.count)
    }

    var overallGPA: Double {
        guard !courseGrades.isEmpty else { return 0.0 }
        let (totalPoints, totalCredits) = courseGrades.reduce((0.0, 0.0)) { result, grade in
            (result.0 + grade.gradePoint * grade.credit, result.1 + grade.credit)
        }
        return totalPoints / totalCredits
    }

    var totalCredits: Double {
        courseGrades.reduce(0.0) { $0 + $1.credit }
    }

    var totalCourses: Int {
        courseGrades.count
    }

    var totalHours: Int {
        courseGrades.reduce(0) { $0 + $1.totalHours }
    }

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
                courseGrades = try await eduHelper.courseService.getCourseGrades()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }
}
