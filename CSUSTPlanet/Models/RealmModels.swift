//
//  RealmModels.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/11.
//

import CSUSTKit
import Foundation
import RealmSwift

//enum RealmModels {
    // MARK: - Dorm
    class Dorm: Object, Identifiable {
        @Persisted(primaryKey: true) var id: ObjectId

        @Persisted var room: String = ""
        @Persisted var buildingID: String = ""
        @Persisted var buildingName: String = ""
        @Persisted var campusID: String = ""
        @Persisted var campusName: String = ""
        @Persisted var schedule: DormSchedule?

        @Persisted var records: List<ElectricityRecord>

        var latestRecord: ElectricityRecord? {
            records.sorted(by: \.date, ascending: false).first
        }

        convenience init(room: String, building: CampusCardHelper.Building) {
            self.init()
            self.room = room
            self.buildingID = building.id
            self.buildingName = building.name
            self.campusID = building.campus.id
            self.campusName = building.campus.rawValue
        }
    }

    // MARK: - DormSchedule
    class DormSchedule: EmbeddedObject {
        @Persisted var id: String = ""
        @Persisted var hour: Int = 0
        @Persisted var minute: Int = 0

        convenience init(id: String, hour: Int, minute: Int) {
            self.init()
            self.id = id
            self.hour = hour
            self.minute = minute
        }
    }

    // MARK: - ElectricityRecord
    class ElectricityRecord: Object, Identifiable {
        @Persisted(primaryKey: true) var id: ObjectId

        @Persisted var electricity: Double = 0
        @Persisted var date: Date = Date()

        @Persisted(originProperty: "records") var dorm: LinkingObjects<Dorm>

        convenience init(electricity: Double, date: Date) {
            self.init()
            self.electricity = electricity
            self.date = date
        }
    }
//}
