//
//  CustomCourseScheduleGRDB.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/8/2.
//

import Foundation
import GRDB

struct CustomCourseScheduleGRDB: Codable, FetchableRecord, MutablePersistableRecord, TableRecord, Identifiable, Equatable, Hashable {
    static let databaseTableName = "custom_course_schedules"

    var id: String = UUID().uuidString
    var name: String
    var semesterStartDate: Date
    var weekCount: Int = 20
    var remarks: String = ""
    var createdAt: Date = Date()

    enum Columns: String, ColumnExpression {
        case id, name, semesterStartDate, weekCount, remarks, createdAt
    }
}
