//
//  GradeAnalysis.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/22.
//

import Foundation
import SwiftData

@Model
class GradeAnalysis {
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

    var totalCourses: Int = 0
    var totalHours: Int = 0
    var totalCredits: Double = 0.0
    var overallAverageGrade: Double = 0.0
    var overallGPA: Double = 0.0

    var gradePointDistribution: [GradePointEntry] = []
    var semesterAverageGrades: [SemesterAverageGrade] = []
    var semesterGPAs: [SemesterGPA] = []

    var lastUpdated: Date = Date()

    init(
        totalCourses: Int,
        totalHours: Int,
        totalCredits: Double,
        overallAverageGrade: Double,
        overallGPA: Double,
        gradePointDistribution: [GradePointEntry],
        semesterAverageGrades: [SemesterAverageGrade],
        semesterGPAs: [SemesterGPA],
        lastUpdated: Date
    ) {
        self.totalCourses = totalCourses
        self.totalHours = totalHours
        self.totalCredits = totalCredits
        self.overallAverageGrade = overallAverageGrade
        self.overallGPA = overallGPA
        self.gradePointDistribution = gradePointDistribution
        self.semesterAverageGrades = semesterAverageGrades
        self.semesterGPAs = semesterGPAs
        self.lastUpdated = lastUpdated
    }
}
