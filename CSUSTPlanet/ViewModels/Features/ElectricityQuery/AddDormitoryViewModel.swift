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
    private var campusCardHelper: CampusCardHelper
    private var modelContext: ModelContext
    private var dorms: [Dorm]

    @Published var isShowingAddDormPopover: Bool {
        didSet {
            isShowingAddDormPopoverBinding.wrappedValue = isShowingAddDormPopover
        }
    }

    private var isShowingAddDormPopoverBinding: Binding<Bool>

    @Published var isShowingError: Bool = false
    @Published var errorMessage: String = ""

    @Published var selectedCampus: Campus = .jinpenling
    @Published var selectedBuildingID: String = ""
    @Published var room: String = ""

    @Published var buildings: [Campus: [Building]] = [:]
    @Published var isBuildingsLoading: Bool = false

    init(dorms: [Dorm], modelContext: ModelContext, isShowingAddDormitoryPopoverBinding: Binding<Bool>) {
        self.campusCardHelper = CampusCardHelper()
        self.dorms = dorms
        self.modelContext = modelContext
        self.isShowingAddDormPopover = isShowingAddDormitoryPopoverBinding.wrappedValue
        self.isShowingAddDormPopoverBinding = isShowingAddDormitoryPopoverBinding
    }

    func handleCampusPickerChange(oldCampus: Campus, newCampus: Campus) {
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

    func handleAddDormitory() {
        let building = buildings[selectedCampus]?.first(where: { $0.id == selectedBuildingID })
        guard let building = building else {
            errorMessage = "请选择有效的宿舍楼"
            isShowingError = true
            return
        }

        let dorm = Dorm(room: room, building: building)
        if dorms.contains(where: { $0.room == dorm.room && $0.buildingID == building.id && $0.buildingName == building.name }) {
            errorMessage = "该宿舍信息已存在"
            isShowingError = true
            return
        }

        modelContext.insert(dorm)
        isShowingAddDormPopover = false
    }
}
