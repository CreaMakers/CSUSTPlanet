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
    func suggestedEntities() async throws -> [DormEntity] {
        let dorms = try SharedModelUtil.context.fetch(FetchDescriptor<Dorm>())
        return dorms.map { DormEntity(dorm: $0) }
    }

    func entities(for identifiers: [UUID]) async throws -> [DormEntity] {
        let predicate = #Predicate<Dorm> { dorm in
            identifiers.contains(dorm.id)
        }
        let dorms = try SharedModelUtil.context.fetch(FetchDescriptor(predicate: predicate))
        return dorms.map { DormEntity(dorm: $0) }
    }

    func defaultResult() async -> DormEntity? {
        try? await suggestedEntities().first
    }
}
