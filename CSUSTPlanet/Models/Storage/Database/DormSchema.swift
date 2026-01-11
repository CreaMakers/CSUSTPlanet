//
//  DormSchema.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/1/11.
//

import CSUSTKit
import Foundation
import SwiftData

enum DormSchemaV1: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        return [Dorm.self, ElectricityRecord.self]
    }

    static var versionIdentifier: Schema.Version = Schema.Version(1, 0, 0)

    @Model
    class Dorm: Identifiable {
        var id: UUID = UUID()
        var room: String = ""
        var buildingID: String = ""
        var buildingName: String = ""
        var campusID: String = ""
        var campusName: String = ""
        var isFavorite: Bool = false
        @Relationship(deleteRule: .cascade, inverse: \ElectricityRecord.dorm) var records: [ElectricityRecord]? = []
        var scheduleHour: Int?
        var scheduleMinute: Int?
        init(room: String, building: CampusCardHelper.Building) {
            self.room = room
            self.buildingID = building.id
            self.buildingName = building.name
            self.campusID = building.campus.id
            self.campusName = building.campus.rawValue
        }
        var scheduleEnabled: Bool {
            return scheduleHour != nil && scheduleMinute != nil
        }
        var lastRecord: ElectricityRecord? {
            return records?.sorted(by: { $0.date > $1.date }).first
        }
    }

    @Model
    class ElectricityRecord {
        var electricity: Double = 0
        var date: Date = Date()
        var dorm: Dorm?
        init(electricity: Double, date: Date, dorm: Dorm? = nil) {
            self.electricity = electricity
            self.date = date
            self.dorm = dorm
        }
    }
}

enum DormSchemaV2: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        return [Dorm.self, ElectricityRecord.self]
    }

    static var versionIdentifier: Schema.Version = Schema.Version(2, 0, 0)

    @Model
    class Dorm: Identifiable {
        var id: UUID = UUID()
        var room: String = ""
        var buildingID: String = ""
        var buildingName: String = ""
        var campusID: String = ""
        var campusName: String = ""
        var isFavorite: Bool = false
        @Relationship(deleteRule: .cascade, inverse: \ElectricityRecord.dorm) var records: [ElectricityRecord]? = []
        var lastFetchDate: Date?
        var scheduleHour: Int?
        var scheduleMinute: Int?
        init(room: String, building: CampusCardHelper.Building) {
            self.room = room
            self.buildingID = building.id
            self.buildingName = building.name
            self.campusID = building.campus.id
            self.campusName = building.campus.rawValue
        }
        var scheduleEnabled: Bool {
            return scheduleHour != nil && scheduleMinute != nil
        }
        var lastRecord: ElectricityRecord? {
            return records?.sorted(by: { $0.date > $1.date }).first
        }
    }

    @Model
    class ElectricityRecord {
        var electricity: Double = 0
        var date: Date = Date()
        var dorm: Dorm?
        init(electricity: Double, date: Date, dorm: Dorm? = nil) {
            self.electricity = electricity
            self.date = date
            self.dorm = dorm
        }
    }
}

typealias Dorm = DormSchemaV2.Dorm
typealias ElectricityRecord = DormSchemaV2.ElectricityRecord
