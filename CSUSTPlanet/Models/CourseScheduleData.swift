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

struct CourseScheduleData: Codable, Equatable {
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

/// 当前生效课表：数据、模式与名称的聚合
struct ActiveCourseSchedule: Codable, Equatable {
    /// 当前生效的课表数据（默认课表取学校缓存，自定义课表读 GRDB）
    var data: CourseScheduleData?
    /// 是否为自定义课表模式
    var isCustomSchedule: Bool = false
    /// 课表名称：自定义课表为课表名，默认课表为学期名
    var scheduleName: String?
}
