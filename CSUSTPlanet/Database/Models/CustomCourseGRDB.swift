//
//  CustomCourseGRDB.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/8/2.
//

import Foundation
import GRDB

struct CustomCourseGRDB: Codable, FetchableRecord, MutablePersistableRecord, TableRecord, Identifiable, Equatable, Hashable {
    static let databaseTableName = "custom_courses"

    var id: String = UUID().uuidString
    var scheduleId: String
    var courseName: String
    var teacher: String?
    var groupName: String?

    enum Columns: String, ColumnExpression {
        case id, scheduleId, courseName, teacher, groupName
    }
}
