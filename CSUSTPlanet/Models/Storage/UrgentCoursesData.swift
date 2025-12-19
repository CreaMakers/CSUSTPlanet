//
//  UrgentCoursesData.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import Foundation
import SwiftData

struct UrgentCoursesData: Codable {
    struct Course: Codable {
        var name: String
        var id: String
    }

    var courses: [Course]

    static func fromCourses(_ courses: [(name: String, id: String)]) -> UrgentCoursesData {
        let courseData = courses.map { Course(name: $0.name, id: $0.id) }
        return UrgentCoursesData(courses: courseData)
    }
}
