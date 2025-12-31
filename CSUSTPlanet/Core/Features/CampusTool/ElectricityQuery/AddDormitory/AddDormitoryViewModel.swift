//
//  AddDormitoryViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/10.
//

import CSUSTKit
import Foundation
import SwiftData
import SwiftUI

@MainActor
class AddDormitoryViewModel: ObservableObject {
    private let campusCardHelper = CampusCardHelper()
    private let modelContext = SharedModelUtil.mainContext

    @Published var isShowingError: Bool = false
    @Published var errorMessage: String = ""

    @Published var selectedCampus: CampusCardHelper.Campus = .jinpenling
    @Published var selectedBuildingID: String = ""
    @Published var room: String = ""

    @Published var buildings: [CampusCardHelper.Campus: [CampusCardHelper.Building]] = [:]
    @Published var isBuildingsLoading: Bool = false

    func handleCampusPickerChange(oldCampus: CampusCardHelper.Campus, newCampus: CampusCardHelper.Campus) {
        if let firstBuilding = buildings[newCampus]?.first {
            selectedBuildingID = firstBuilding.id
        } else {
            selectedBuildingID = ""
        }
    }

    func loadBuildings() {
        isBuildingsLoading = true
        Task {
            defer {
                isBuildingsLoading = false
            }
            do {
                let jinpenlingBuildings = try await campusCardHelper.getBuildings(for: .jinpenling)
                buildings[.jinpenling] = jinpenlingBuildings.sorted { $0.name < $1.name }

                let yuntangBuildings = try await campusCardHelper.getBuildings(for: .yuntang)
                buildings[.yuntang] = yuntangBuildings.sorted { $0.name < $1.name }

                if let firstBuilding = buildings[selectedCampus]?.first {
                    selectedBuildingID = firstBuilding.id
                }
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func handleAddDormitory(_ isShowingAddDormSheet: Binding<Bool>) {
        let building = buildings[selectedCampus]?.first(where: { $0.id == selectedBuildingID })
        guard let building = building else {
            errorMessage = "请选择有效的宿舍楼"
            isShowingError = true
            return
        }

        let dorm = Dorm(room: room, building: building)
        let fetchDescriptor = FetchDescriptor<Dorm>()
        guard let dorms = try? modelContext.fetch(fetchDescriptor) else {
            errorMessage = "无法访问数据库"
            isShowingError = true
            return
        }
        if dorms.contains(where: { $0.room == dorm.room && $0.buildingID == building.id && $0.buildingName == building.name }) {
            errorMessage = "该宿舍信息已存在"
            isShowingError = true
            return
        }

        modelContext.insert(dorm)
        do {
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
            return
        }
        isShowingAddDormSheet.wrappedValue = false
    }
}
