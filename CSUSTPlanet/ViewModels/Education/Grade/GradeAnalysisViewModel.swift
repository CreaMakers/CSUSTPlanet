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

    @Published var selectedTab: Int = 0

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

    var gradeRangeDistribution: [(range: String, count: Int)] {
        let ranges = [
            (range: "90-100", min: 90, max: 100),
            (range: "85-89", min: 85, max: 89),
            (range: "82-84", min: 82, max: 84),
            (range: "78-81", min: 78, max: 81),
            (range: "75-77", min: 75, max: 77),
            (range: "72-74", min: 72, max: 74),
            (range: "68-71", min: 68, max: 71),
            (range: "64-67", min: 64, max: 67),
            (range: "60-63", min: 60, max: 63),
            (range: "≤59", min: 0, max: 59)
        ]

        return ranges.compactMap { range in
            let count = courseGrades.filter { grade in
                grade.grade >= range.min && grade.grade <= range.max
            }.count
            return count > 0 ? (range: range.range, count: count) : nil
        }
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
