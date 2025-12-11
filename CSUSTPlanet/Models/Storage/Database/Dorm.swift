//
//  Dorm.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import CSUSTKit
import Foundation
import SwiftData

// MARK: - 1.4
@Model
class Dorm: Identifiable {
    var id: UUID = UUID()

    var room: String = ""

    var buildingID: String = ""
    var buildingName: String = ""
    var campusID: String = ""
    var campusName: String = ""

    var isFavorite: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \ElectricityRecord.dorm)
    var records: [ElectricityRecord]? = []

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

// MARK: - 1.3
// @Model
// class Dorm: Identifiable {
//     var id: UUID = UUID()
//
//     var room: String = ""
//
//     var buildingID: String = ""
//     var buildingName: String = ""
//     var campusID: String = ""
//     var campusName: String = ""
//
//     @Relationship(deleteRule: .cascade, inverse: \ElectricityRecord.dorm)
//     var records: [ElectricityRecord]? = []
//
//     var scheduleHour: Int?
//     var scheduleMinute: Int?
//
//     init(room: String, building: CampusCardHelper.Building) {
//         self.room = room
//         self.buildingID = building.id
//         self.buildingName = building.name
//         self.campusID = building.campus.id
//         self.campusName = building.campus.rawValue
//     }
//
//     var scheduleEnabled: Bool {
//         return scheduleHour != nil && scheduleMinute != nil
//     }
//
//     var lastRecord: ElectricityRecord? {
//         return records?.sorted(by: { $0.date > $1.date }).first
//     }
// }

// MARK: - 1.0
// @Model
// class Dorm: Identifiable {
//     var id: UUID = UUID()

//     var room: String = ""

//     var buildingID: String = ""
//     var buildingName: String = ""
//     var campusID: String = ""
//     var campusName: String = ""

//     @Relationship(deleteRule: .cascade, inverse: \ElectricityRecord.dorm)
//     var records: [ElectricityRecord]? = []

//     var scheduleId: String?
//     var scheduleHour: Int?
//     var scheduleMinute: Int?

//     init(room: String, building: CampusCardHelper.Building) {
//         self.room = room
//         self.buildingID = building.id
//         self.buildingName = building.name
//         self.campusID = building.campus.id
//         self.campusName = building.campus.rawValue
//     }

//     var lastRecord: ElectricityRecord? {
//         return records?.sorted(by: { $0.date > $1.date }).first
//     }
// }
