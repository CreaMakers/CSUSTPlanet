//
//  GradeAnalysis.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/22.
//

import CSUSTKit
import Foundation
import SwiftData

struct GradePointEntry: Codable {
    var gradePoint: Double
    var count: Int
}

struct SemesterAverageGrade: Codable {
    var semester: String
    var average: Double
}

struct SemesterGPA: Codable {
    var semester: String
    var gpa: Double
}

struct GradeAnalysisData: Codable {
    var totalCourses: Int
    var totalHours: Int
    var totalCredits: Double
    var overallAverageGrade: Double
    var overallGPA: Double
    var gradePointDistribution: [GradePointEntry]
    var semesterAverageGrades: [SemesterAverageGrade]
    var semesterGPAs: [SemesterGPA]
    var lastUpdated: Date

    static func fromCourseGrades(_ courseGrades: [CourseGrade]) -> GradeAnalysisData {
        let totalCourses = courseGrades.count
        let totalHours = courseGrades.reduce(0) { $0 + $1.totalHours }
        let totalCredits = courseGrades.reduce(0) { $0 + $1.credit }
        let overallAverageGrade = totalCourses > 0 ? Double(courseGrades.reduce(0) { $0 + $1.grade }) / Double(totalCourses) : 0.0
        let overallGPA = totalCredits > 0 ? courseGrades.reduce(0) { $0 + $1.gradePoint * $1.credit } / totalCredits : 0.0
        let gradePointDistribution = courseGrades.reduce(into: [Double: Int]()) { result, course in
            result[course.gradePoint, default: 0] += 1
        }.map { GradePointEntry(gradePoint: $0.key, count: $0.value) }
        let semesterAverageGrades = Dictionary(grouping: courseGrades, by: { $0.semester }).map { semester, grades in
            SemesterAverageGrade(semester: semester, average: Double(grades.reduce(0) { $0 + $1.grade }) / Double(grades.count))
        }
        let semesterGPAs = Dictionary(grouping: courseGrades, by: { $0.semester }).map { semester, grades in
            let totalCredits = grades.reduce(0) { $0 + $1.credit }
            let totalGradePoints = grades.reduce(0) { $0 + $1.gradePoint * $1.credit }
            let gpa = totalCredits > 0 ? totalGradePoints / totalCredits : 0.0
            return SemesterGPA(semester: semester, gpa: gpa)
        }
        return GradeAnalysisData(
            totalCourses: totalCourses,
            totalHours: totalHours,
            totalCredits: totalCredits,
            overallAverageGrade: overallAverageGrade,
            overallGPA: overallGPA,
            gradePointDistribution: gradePointDistribution.sorted { $0.gradePoint > $1.gradePoint },
            semesterAverageGrades: semesterAverageGrades.sorted { $0.semester < $1.semester },
            semesterGPAs: semesterGPAs.sorted { $0.semester < $1.semester },
            lastUpdated: .now
        )
    }

    static func empty() -> GradeAnalysisData {
        return GradeAnalysisData(
            totalCourses: 0,
            totalHours: 0,
            totalCredits: 0.0,
            overallAverageGrade: 0.0,
            overallGPA: 0.0,
            gradePointDistribution: [],
            semesterAverageGrades: [],
            semesterGPAs: [],
            lastUpdated: .now
        )
    }
}

@Model
class GradeAnalysis {
    var data: GradeAnalysisData = GradeAnalysisData.empty()

    init(
        data: GradeAnalysisData,
    ) {
        self.data = data
    }
}
