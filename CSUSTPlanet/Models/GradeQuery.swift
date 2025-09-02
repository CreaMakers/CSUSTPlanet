//
//  GradeQuery.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/3.
//

import CSUSTKit
import Foundation
import SwiftData

struct GradeQueryData: Codable {
    var courseGrades: [EduHelper.CourseGrade]
    var lastUpdated: Date

    static func fromCourseGrades(courseGrades: [EduHelper.CourseGrade]) -> GradeQueryData {
        return GradeQueryData(courseGrades: courseGrades, lastUpdated: .now)
    }

    static func empty() -> GradeQueryData {
        return GradeQueryData(courseGrades: [], lastUpdated: .now)
    }
}

@Model
class GradeQuery {
    var data: GradeQueryData = GradeQueryData.empty()

    init(data: GradeQueryData) {
        self.data = data
    }
}
