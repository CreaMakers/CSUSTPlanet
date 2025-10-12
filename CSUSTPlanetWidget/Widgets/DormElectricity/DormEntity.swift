//
//  DormEntity.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/21.
//

import AppIntents
import Foundation

struct DormEntity: AppEntity, Identifiable {
    var id: String

    var room: String

    var buildingName: String
    var buildingID: String
    var campusID: String
    var campusName: String

    var records: [ElectricityRecord]

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "宿舍")

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(buildingName) \(room)"
        )
    }

    static var defaultQuery = DormQuery()

    struct ElectricityRecord: Identifiable {
        let id: String

        var electricity: Double
        var date: Date
    }

    init(dorm: Dorm) {
        self.id = dorm.id.stringValue

        self.room = dorm.room
        self.buildingID = dorm.buildingID
        self.buildingName = dorm.buildingName
        self.campusID = dorm.campusID
        self.campusName = dorm.campusName

        self.records = dorm.records.map { ElectricityRecord(id: $0.id.stringValue, electricity: $0.electricity, date: $0.date) }
    }

    var last: ElectricityRecord? {
        return records.sorted(by: { $0.date > $1.date }).first
    }
}
