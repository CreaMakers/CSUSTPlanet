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
    /// 课表总周数，nil 表示默认 20 周（学校课表）
    var weekCount: Int?

    init(
        semester: String?,
        semesterStartDate: Date,
        courses: [EduHelper.Course],
        remarks: [String],
        weekCount: Int? = nil
    ) {
        self.semester = semester
        self.semesterStartDate = semesterStartDate
        self.courses = courses
        self.remarks = remarks
        self.weekCount = weekCount
    }
}
