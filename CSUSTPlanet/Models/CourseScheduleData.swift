//
//  CourseSchedule.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/23.
//

import CSUSTKit
import Foundation
import SwiftUI

struct CourseDisplayInfo: Identifiable, Codable {
    var id = UUID()
    let course: EduHelper.Course
    let session: EduHelper.ScheduleSession

    init(course: EduHelper.Course, session: EduHelper.ScheduleSession) {
        self.course = course
        self.session = session
    }
}

struct CourseScheduleData: Codable {
    var semester: String?
    var semesterStartDate: Date
    var courses: [EduHelper.Course]
    var remarks: [String]

    init(semester: String?, semesterStartDate: Date, courses: [EduHelper.Course], remarks: [String]) {
        self.semester = semester
        self.semesterStartDate = semesterStartDate
        self.courses = courses
        self.remarks = remarks
    }
}
