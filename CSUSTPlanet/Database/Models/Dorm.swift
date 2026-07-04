//
//  Dorm.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/21.
//

import Foundation
import GRDB

struct DormGRDB: Codable, FetchableRecord, MutablePersistableRecord, TableRecord, Identifiable, Equatable, Hashable {
    static let databaseTableName = "dorms"

    var id: Int64?
    var room: String
    var buildingName: String
    var campusName: String
    var isFavorite: Bool
    var lastFetchDate: Date?
    var lastFetchElectricity: Double?
    var hasFetchedElectricity: Bool { return lastFetchDate != nil && lastFetchElectricity != nil }

    enum Columns: String, ColumnExpression {
        case id
        case campusName, buildingName, room
        case isFavorite
        case lastFetchDate, lastFetchElectricity
    }

    static let records = hasMany(ElectricityRecordGRDB.self)
}

extension DormGRDB {
    static func toggleFavorite(dormID: Int64, in db: Database) throws {
        let request = DormGRDB.filter(Columns.id == dormID).select(Columns.isFavorite)
        guard let isCurrentlyFavorite = try Bool.fetchOne(db, request) else { return }

        if isCurrentlyFavorite {
            try DormGRDB.filter(Columns.id == dormID)
                .updateAll(db, Columns.isFavorite.set(to: false))
        } else {
            try DormGRDB.filter(Columns.isFavorite == true)
                .updateAll(db, Columns.isFavorite.set(to: false))
            try DormGRDB.filter(Columns.id == dormID)
                .updateAll(db, Columns.isFavorite.set(to: true))
        }
    }

    static func updateElectricity(dormID: Int64, electricity: Double, in db: Database) throws {
        let lastValue = try Double.fetchOne(db, DormGRDB.filter(Columns.id == dormID).select(Columns.lastFetchElectricity))

        let now = Date()

        if let lastValue = lastValue, abs(lastValue - electricity) < 0.001 {
            try DormGRDB.filter(Columns.id == dormID)
                .updateAll(db, Columns.lastFetchDate.set(to: now))
        } else {
            var record = ElectricityRecordGRDB(id: nil, electricity: electricity, date: now, dormID: dormID)
            try record.insert(db)

            try DormGRDB.filter(Columns.id == dormID)
                .updateAll(db, [Columns.lastFetchDate.set(to: now), Columns.lastFetchElectricity.set(to: electricity)])
        }
    }

    static func deleteElectricityRecord(dormID: Int64, recordID: Int64, in db: Database) throws {
        let deleted = try ElectricityRecordGRDB.deleteOne(db, key: recordID)

        if deleted {
            let hasRemaining = try
                !ElectricityRecordGRDB
                .filter(ElectricityRecordGRDB.Columns.dormID == dormID)
                .isEmpty(db)

            if !hasRemaining {
                try DormGRDB.filter(id: dormID)
                    .updateAll(db, [Columns.lastFetchDate.set(to: nil), Columns.lastFetchElectricity.set(to: nil)])
            }
        }
    }

    static func deleteAllElectricityRecords(dormID: Int64, in db: Database) throws {
        try ElectricityRecordGRDB
            .filter(ElectricityRecordGRDB.Columns.dormID == dormID)
            .deleteAll(db)

        try DormGRDB.filter(id: dormID)
            .updateAll(db, [Columns.lastFetchDate.set(to: nil), Columns.lastFetchElectricity.set(to: nil)])
    }
}
