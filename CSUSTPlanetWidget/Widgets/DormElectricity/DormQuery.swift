//
//  DormQuery.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/21.
//

import AppIntents
import Foundation
import SwiftData

struct DormQuery: EntityQuery {
    @Dependency(key: "ModelContainer")
    private var modelContainer: ModelContainer

    func suggestedEntities() async throws -> [DormEntity] {
        let context = ModelContext(modelContainer)
        let dorms = try context.fetch(FetchDescriptor<Dorm>())
        return dorms.map { DormEntity(dorm: $0) }
    }

    func entities(for identifiers: [UUID]) async throws -> [DormEntity] {
        let context = ModelContext(modelContainer)
        let predicate = #Predicate<Dorm> { dorm in
            identifiers.contains(dorm.id)
        }
        let dorms = try context.fetch(FetchDescriptor(predicate: predicate))
        return dorms.map { DormEntity(dorm: $0) }
    }

    func defaultResult() async -> DormEntity? {
        try? await suggestedEntities().first
    }
}
