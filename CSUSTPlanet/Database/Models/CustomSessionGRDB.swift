//
//  CustomSessionGRDB.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/8/2.
//

import Foundation
import GRDB

struct CustomSessionGRDB: Codable, FetchableRecord, MutablePersistableRecord, TableRecord, Identifiable, Equatable, Hashable {
    static let databaseTableName = "custom_sessions"

    var id: String = UUID().uuidString
    var courseId: String
    var dayOfWeek: Int
    var startSection: Int
    var endSection: Int
    var classroom: String?
    var weeks: JSONIntArray

    enum Columns: String, ColumnExpression {
        case id, courseId, dayOfWeek, startSection, endSection, classroom, weeks
    }
}

struct JSONIntArray: Codable, Equatable, Hashable, DatabaseValueConvertible {
    var values: [Int]

    init(_ values: [Int] = []) {
        self.values = values
    }

    init?(databaseValue: DatabaseValue) {
        guard let json = String.fromDatabaseValue(databaseValue),
            let data = json.data(using: .utf8),
            let values = try? JSONDecoder().decode([Int].self, from: data)
        else {
            return nil
        }
        self.values = values
    }

    var databaseValue: DatabaseValue {
        guard let data = try? JSONEncoder().encode(values),
            let json = String(data: data, encoding: .utf8)
        else {
            return "[]".databaseValue
        }
        return json.databaseValue
    }
}
