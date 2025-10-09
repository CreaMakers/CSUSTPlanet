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
    let course: EduHelper.Course
    let session: EduHelper.ScheduleSession
}

struct CourseScheduleData: Codable {
    var semester: String?
    var semesterStartDate: Date
    var courses: [EduHelper.Course]

    var weeklyCourses: [Int: [CourseDisplayInfo]] {
        var processedCourses: [Int: [CourseDisplayInfo]] = [:]

        for course in courses {
            for session in course.sessions {
                let displayInfo = CourseDisplayInfo(course: course, session: session)

                for week in session.weeks {
                    processedCourses[week, default: []].append(displayInfo)
                }
            }
        }
        return processedCourses
    }
}
