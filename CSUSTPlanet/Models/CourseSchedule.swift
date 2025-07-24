//
//  CourseSchedule.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/23.
//

import CSUSTKit
import Foundation
import SwiftData
import SwiftUI

struct CourseDisplayInfo: Identifiable, Codable {
    var id = UUID()
    let course: Course
    let session: ScheduleSession
}

struct CourseScheduleData: Codable {
    var semester: String?
    var semesterStartDate: Date
    var weeklyCourses: [Int: [CourseDisplayInfo]]
    var courses: [Course]
    var lastUpdated: Date

    static func fromCourses(courses: [Course], semester: String?, semesterStartDate: Date) -> CourseScheduleData {
        var processedCourses: [Int: [CourseDisplayInfo]] = [:]

        for course in courses {
            for session in course.sessions {
                let displayInfo = CourseDisplayInfo(course: course, session: session)

                for week in session.weeks {
                    processedCourses[week, default: []].append(displayInfo)
                }
            }
        }
        return CourseScheduleData(semester: semester, semesterStartDate: semesterStartDate, weeklyCourses: processedCourses, courses: courses, lastUpdated: .now)
    }

    static func empty() -> CourseScheduleData {
        return CourseScheduleData(semester: "", semesterStartDate: .now, weeklyCourses: [:], courses: [], lastUpdated: .now)
    }
}

@Model
class CourseSchedule {
    var data: CourseScheduleData = CourseScheduleData.empty()

    init(data: CourseScheduleData) {
        self.data = data
    }
}
