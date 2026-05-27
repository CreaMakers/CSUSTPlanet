//
//  AddDormViewModel.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/21.
//

import CSUSTKit
import Foundation
import SwiftUI

@MainActor
@Observable
final class AddDormViewModel: Observable {
    @ObservationIgnored private let campusCardHelper = CampusCardHelper()

    var errorToast: ToastState = .errorTitle

    var selectedCampus: CampusCardHelper.Campus = .jinpenling
    var selectedBuildingID: String = ""
    var room: String = ""
    var trimmedRoom: String { room.trimmingCharacters(in: .whitespacesAndNewlines) }

    var buildings: [CampusCardHelper.Campus: [CampusCardHelper.Building]] = [:]
    var isBuildingsLoading: Bool = false

    var selectedCampusBuildings: [CampusCardHelper.Building] {
        buildings[selectedCampus] ?? []
    }

    var selectedBuilding: CampusCardHelper.Building? {
        selectedCampusBuildings.first(where: { $0.id == selectedBuildingID })
    }

    @ObservationIgnored var isInitial = true

    func loadInitial() async {
        guard isInitial else { return }
        isInitial = false
        await loadBuildings()
    }

    func loadBuildings() async {
        withAnimation { isBuildingsLoading = true }
        defer {
            withAnimation { isBuildingsLoading = false }
        }

        do {
            // TODO: Need to fix
            let jinpenlingBuildings = try await campusCardHelper.getBuildings(campus: .jinpenling)
            buildings[.jinpenling] = jinpenlingBuildings.sorted { $0.name < $1.name }

            let yuntangBuildings = try await campusCardHelper.getBuildings(campus: .yuntang)
            buildings[.yuntang] = yuntangBuildings.sorted { $0.name < $1.name }

            if let firstBuilding = buildings[selectedCampus]?.first {
                selectedBuildingID = firstBuilding.id
            }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func handleCampusPickerChange(oldCampus: CampusCardHelper.Campus, newCampus: CampusCardHelper.Campus) {
        if let firstBuilding = buildings[newCampus]?.first {
            selectedBuildingID = firstBuilding.id
        } else {
            selectedBuildingID = ""
        }
    }
}
