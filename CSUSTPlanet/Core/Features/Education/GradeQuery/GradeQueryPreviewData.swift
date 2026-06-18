//
//  GradeQueryPreviewData.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/18.
//

import CSUSTKit
import Foundation

enum GradeQueryPreviewData {
    static let grades: [EduHelper.CourseGrade] = [
        makeGrade(
            semester: "2024-2025-2",
            courseID: "A010101",
            courseName: "移动应用开发",
            groupName: "01",
            grade: 94,
            credit: 3,
            totalHours: 48,
            gradePoint: 4.3,
            courseAttribute: "必修",
            courseNature: .professionalCourse,
            courseCategory: "专业课"
        ),
        makeGrade(
            semester: "2024-2025-2",
            courseID: "A010102",
            courseName: "数据库系统",
            grade: 88,
            credit: 3,
            totalHours: 48,
            gradePoint: 3.7,
            courseAttribute: "必修",
            courseNature: .professionalBasicCourse,
            courseCategory: "专业基础课"
        ),
        makeGrade(
            semester: "2024-2025-1",
            courseID: "B020101",
            courseName: "大学英语",
            grade: 91,
            credit: 2,
            totalHours: 32,
            gradePoint: 4.0,
            courseAttribute: "限选",
            courseNature: .publicBasicCourse,
            courseCategory: "公共基础课"
        ),
    ]

    static var groupedGrades: [(semester: String, grades: [EduHelper.CourseGrade])] {
        let grouped = Dictionary(grouping: grades) { $0.semester }
        return grouped.keys.sorted(by: >).map { (semester: $0, grades: grouped[$0] ?? []) }
    }

    static var semesterGPAs: [String: Double] {
        Dictionary(grouping: grades, by: { $0.semester }).reduce(into: [:]) { result, entry in
            let totalCredits = entry.value.reduce(0) { $0 + $1.credit }
            let totalGradePoints = entry.value.reduce(0) { $0 + $1.gradePoint * $1.credit }
            result[entry.key] = totalCredits > 0 ? totalGradePoints / totalCredits : 0.0
        }
    }

    static let detail = EduHelper.GradeDetail(
        components: [
            EduHelper.GradeComponent(type: "平时成绩", grade: 92, ratio: 30),
            EduHelper.GradeComponent(type: "实验成绩", grade: 96, ratio: 20),
            EduHelper.GradeComponent(type: "期末成绩", grade: 90, ratio: 50),
        ],
        totalGrade: 93
    )

    static func makeGrade(
        semester: String = "2024-2025-2",
        courseID: String = "A010101",
        courseName: String = "移动应用开发",
        groupName: String = "",
        grade: Int = 90,
        credit: Double = 3,
        totalHours: Double = 48,
        gradePoint: Double = 4.0,
        courseAttribute: String = "必修",
        courseNature: EduHelper.CourseNature = .professionalCourse,
        courseCategory: String = "专业课"
    ) -> EduHelper.CourseGrade {
        EduHelper.CourseGrade(
            semester: semester,
            courseID: courseID,
            courseName: courseName,
            groupName: groupName,
            grade: grade,
            gradeDetailUrl: "https://example.com/grade-detail",
            studyMode: "主修",
            gradeIdentifier: "",
            credit: credit,
            totalHours: totalHours,
            gradePoint: gradePoint,
            retakeSemester: "",
            assessmentMethod: "考试",
            examNature: "正常考试",
            courseAttribute: courseAttribute,
            courseNature: courseNature,
            courseCategory: courseCategory
        )
    }
}
