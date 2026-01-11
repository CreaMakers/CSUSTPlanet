//
//  DormMigrationPlan.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/1/11.
//

import Foundation
import SwiftData

enum DormMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        return [DormSchemaV1.self, DormSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        return [migrateV1ToV2]
    }

    static let migrateV1ToV2: MigrationStage = MigrationStage.custom(
        fromVersion: DormSchemaV1.self,
        toVersion: DormSchemaV2.self,
        willMigrate: nil,
        didMigrate: { context in
            let descriptor = FetchDescriptor<DormSchemaV2.Dorm>()
            let dorms = try context.fetch(descriptor)
            for dorm in dorms {
                dorm.lastFetchDate = dorm.records?.compactMap(\.date).max()
            }
            try context.save()
        }
    )
}
