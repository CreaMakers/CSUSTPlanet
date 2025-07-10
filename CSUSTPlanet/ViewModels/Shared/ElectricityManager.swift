//
//  ElectricityManager.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import CSUSTKit
import Foundation
import SwiftData
import SwiftUI

enum ElectricityManagerError: LocalizedError {
    case getElectricityFailed(String)

    var errorDescription: String? {
        switch self {
        case .getElectricityFailed(let message):
            return "Get electricity failed: \(message)"
        }
    }
}

@MainActor
class ElectricityManager: ObservableObject {
    let campusCardHelper = CampusCardHelper()

    @Published var buildings: [Campus: [Building]] = [:]
    @Published var isBuildingsLoading = false

    func loadBuildings() async throws {
        guard buildings.isEmpty else { return }
        isBuildingsLoading = true
        defer {
            isBuildingsLoading = false
        }

        let jinpenlingBuildings = try await campusCardHelper.getBuildings(for: .jinpenling)
        buildings[.jinpenling] = jinpenlingBuildings.sorted { $0.name < $1.name }

        let yuntangBuildings = try await campusCardHelper.getBuildings(for: .yuntang)
        buildings[.yuntang] = yuntangBuildings.sorted { $0.name < $1.name }
    }

    func getElectricity(dorm: Dorm) async throws -> Double {
        guard let campus = Campus(rawValue: dorm.campusName) else {
            throw ElectricityManagerError.getElectricityFailed("Invalid campus ID \(dorm.campusID)")
        }

        let building = Building(name: dorm.buildingName, id: dorm.buildingID, campus: campus)
        return try await campusCardHelper.getElectricity(building: building, room: dorm.room)
    }

    func refreshElectricity(dorm: Dorm, modelContext: ModelContext) async throws {
        let electricity = try await getElectricity(dorm: dorm)

        if let lastRecord = getLastRecord(records: dorm.records) {
            if lastRecord.electricity == electricity {
                return
            }
        }

        let electricityRecord = ElectricityRecord(electricity: electricity, date: Date(), dorm: dorm)
        modelContext.insert(electricityRecord)
    }

    func getLastRecord(records: [ElectricityRecord]) -> ElectricityRecord? {
        return records.sorted(by: { $0.date > $1.date }).first
    }
}
