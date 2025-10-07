//
//  GradeAnalysisData.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2025/10/7.
//

import CSUSTKit
import Foundation

struct GradeAnalysisData {
    var totalCourses: Int
    var totalHours: Int
    var totalCredits: Double
    var overallAverageGrade: Double
    var overallGPA: Double
    var weightedAverageGrade: Double
    var gradePointDistribution: [(gradePoint: Double, count: Int)]
    var semesterAverageGrades: [(semester: String, average: Double)]
    var semesterGPAs: [(semester: String, gpa: Double)]

    static func fromCourseGrades(_ courseGrades: [EduHelper.CourseGrade]) -> GradeAnalysisData {
        let totalCourses = courseGrades.count
        let totalHours = courseGrades.reduce(0) { $0 + $1.totalHours }
        let totalCredits = courseGrades.reduce(0) { $0 + $1.credit }
        let overallAverageGrade = totalCourses > 0 ? Double(courseGrades.reduce(0) { $0 + $1.grade }) / Double(totalCourses) : 0.0
        let overallGPA = totalCredits > 0 ? courseGrades.reduce(0) { $0 + $1.gradePoint * $1.credit } / totalCredits : 0.0
        let weightedAverageGrade = totalCredits > 0 ? courseGrades.reduce(0) { $0 + (Double($1.grade) * $1.credit) } / totalCredits : 0.0
        let gradePointDistribution = courseGrades.reduce(into: [Double: Int]()) { result, course in
            result[course.gradePoint, default: 0] += 1
        }.map { (gradePoint: $0.key, count: $0.value) }
        let semesterAverageGrades = Dictionary(grouping: courseGrades, by: { $0.semester }).map { semester, grades in
            (semester: semester, average: Double(grades.reduce(0) { $0 + $1.grade }) / Double(grades.count))
        }
        let semesterGPAs = Dictionary(grouping: courseGrades, by: { $0.semester }).map { semester, grades in
            let totalCredits = grades.reduce(0) { $0 + $1.credit }
            let totalGradePoints = grades.reduce(0) { $0 + $1.gradePoint * $1.credit }
            let gpa = totalCredits > 0 ? totalGradePoints / totalCredits : 0.0
            return (semester: semester, gpa: gpa)
        }
        return GradeAnalysisData(
            totalCourses: totalCourses,
            totalHours: totalHours,
            totalCredits: totalCredits,
            overallAverageGrade: overallAverageGrade,
            overallGPA: overallGPA,
            weightedAverageGrade: weightedAverageGrade,
            gradePointDistribution: gradePointDistribution.sorted { $0.gradePoint > $1.gradePoint },
            semesterAverageGrades: semesterAverageGrades.sorted { $0.semester < $1.semester },
            semesterGPAs: semesterGPAs.sorted { $0.semester < $1.semester }
        )
    }
}
