//
//  DormQuery.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/21.
//

import AppIntents
import Foundation
import RealmSwift

struct DormQuery: EntityQuery {
    func suggestedEntities() async throws -> [DormEntity] {
        let realm = try await Realm()
        let dorms = realm.objects(Dorm.self)
        return dorms.map { DormEntity(dorm: $0) }
    }

    func entities(for identifiers: [String]) async throws -> [DormEntity] {
        let realm = try await Realm()
        let dorms = realm.objects(Dorm.self).filter { identifiers.contains($0.id.stringValue) }
        return dorms.map { DormEntity(dorm: $0) }
    }

    func defaultResult() async -> DormEntity? {
        try? await suggestedEntities().first
    }
}
