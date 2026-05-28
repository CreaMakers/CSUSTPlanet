//
//  DatabaseManager.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/21.
//

import Combine
import Foundation
import GRDB
import OSLog
import os

enum DatabaseManagerError: Error, LocalizedError {
    case databaseUnavailable

    var errorDescription: String? {
        switch self {
        case .databaseUnavailable:
            return "数据库不可用"
        }
    }
}

final class DatabaseManager {
    static let shared = DatabaseManager()

    private var databasePool: DatabasePool?
    var pool: DatabasePool? { databasePool }
    var poolThrows: DatabasePool {
        get throws {
            guard let databasePool else {
                throw DatabaseManagerError.databaseUnavailable
            }
            return databasePool
        }
    }

    private(set) var hasFatalError = false
    private(set) var fatalErrorMessage: String = ""

    private init() {
        do {
            var configuration = Configuration()
            configuration.foreignKeysEnabled = true
            configuration.busyMode = .timeout(5)
            configuration.label = "CSUSTPlanet.GRDB"

            let databasePool = try DatabasePool(path: Constants.grdbDatabaseURL.path, configuration: configuration)
            try Self.migrator.migrate(databasePool)
            self.databasePool = databasePool
        } catch {
            self.databasePool = nil
            self.hasFatalError = true
            self.fatalErrorMessage = "数据库初始化失败：\(error.localizedDescription)"
        }
    }

    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_create_dorm_and_electricity_record") { db in
            try db.create(table: DormGRDB.databaseTableName) { t in
                t.autoIncrementedPrimaryKey(DormGRDB.Columns.id.name)
                t.column(DormGRDB.Columns.room.name, .text).notNull()
                t.column("buildingID", .text).notNull()
                t.column(DormGRDB.Columns.buildingName.name, .text).notNull()
                t.column("campusID", .text).notNull()
                t.column(DormGRDB.Columns.campusName.name, .text).notNull()
                t.column(DormGRDB.Columns.isFavorite.name, .boolean).notNull().defaults(to: false)
                t.column(DormGRDB.Columns.lastFetchDate.name, .datetime)
                t.column(DormGRDB.Columns.lastFetchElectricity.name, .double)
                t.column(DormGRDB.Columns.scheduleHour.name, .integer)
                t.column(DormGRDB.Columns.scheduleMinute.name, .integer)
            }

            try db.create(index: "idx_dorm_isFavorite", on: DormGRDB.databaseTableName, columns: [DormGRDB.Columns.isFavorite.name])

            try db.create(table: ElectricityRecordGRDB.databaseTableName) { t in
                t.autoIncrementedPrimaryKey(ElectricityRecordGRDB.Columns.id.name)
                t.column(ElectricityRecordGRDB.Columns.electricity.name, .double).notNull()
                t.column(ElectricityRecordGRDB.Columns.date.name, .datetime).notNull()
                t.column(ElectricityRecordGRDB.Columns.dormID.name, .integer).notNull().references(DormGRDB.databaseTableName, onDelete: .cascade)
            }

            try db.create(index: "idx_electricity_record_dormID_date", on: ElectricityRecordGRDB.databaseTableName, columns: [ElectricityRecordGRDB.Columns.dormID.name, ElectricityRecordGRDB.Columns.date.name])
        }

        migrator.registerMigration("v2_make_dorm_isFavorite_unique") { db in
            let dormTable = DormGRDB.databaseTableName
            let isFavoriteColumn = DormGRDB.Columns.isFavorite.name

            try db.execute(sql: "UPDATE \(dormTable) SET \(isFavoriteColumn) = 0 WHERE \(isFavoriteColumn) != 0")

            try db.drop(index: "idx_dorm_isFavorite")
            try db.execute(sql: "CREATE UNIQUE INDEX idx_dorm_isFavorite_unique ON \(dormTable) (\(isFavoriteColumn)) WHERE \(isFavoriteColumn) = 1")
        }

        migrator.registerMigration("v3_create_matomo_events") { db in
            try db.create(table: MatomoEventGRDB.databaseTableName) { t in
                t.column(MatomoEventGRDB.Columns.id.name, .blob).notNull().primaryKey()
                t.column(MatomoEventGRDB.Columns.payload.name, .blob).notNull()
                t.column(MatomoEventGRDB.Columns.createdAt.name, .datetime).notNull()
            }

            try db.create(index: "idx_matomo_events_createdAt", on: MatomoEventGRDB.databaseTableName, columns: [MatomoEventGRDB.Columns.createdAt.name])
        }

        migrator.registerMigration("v4_drop_buildingID_campusID") { db in
            try db.alter(table: DormGRDB.databaseTableName) { t in
                t.drop(column: "buildingID")
                t.drop(column: "campusID")
            }
        }

        return migrator
    }
}

final class GRDBIPCNotifier {
    static let shared = GRDBIPCNotifier()

    private let notificationName = Constants.grdbIPCName as CFString

    let dbChangedSubject = PassthroughSubject<Void, Never>()

    private init() {
        setupObserver()
    }

    func notifyChange() {
        #if WIDGET
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(self.notificationName),
            nil,
            nil,
            true
        )
        #endif
    }

    private func setupObserver() {
        #if !WIDGET
        let observer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            observer,
            { _, observer, _, _, _ in
                guard let observerInfo = observer else { return }
                let instance = Unmanaged<GRDBIPCNotifier>.fromOpaque(observerInfo).takeUnretainedValue()
                instance.dbChangedSubject.send(())
            },
            self.notificationName,
            nil,
            .deliverImmediately
        )
        #endif
    }
}
