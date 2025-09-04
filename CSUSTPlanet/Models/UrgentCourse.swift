//
//  UrgentCourse.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import Foundation
import SwiftData

struct UrgentCourseData: Codable {
    struct Course: Codable {
        var name: String
        var id: String
    }

    var courses: [Course]
    var lastUpdated: Date

    static func fromCourses(_ courses: [(name: String, id: String)]) -> UrgentCourseData {
        let courseData = courses.map { Course(name: $0.name, id: $0.id) }
        return UrgentCourseData(courses: courseData, lastUpdated: .now)
    }

    static func empty() -> UrgentCourseData {
        return UrgentCourseData(courses: [], lastUpdated: .now)
    }
}

@Model
class UrgentCourse {
    var data: UrgentCourseData = UrgentCourseData.empty()

    init(data: UrgentCourseData) {
        self.data = data
    }
}
