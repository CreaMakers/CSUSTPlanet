//
//  AddDormitoryViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/10.
//

import CSUSTKit
import Foundation
import RealmSwift
import SwiftUI

@MainActor
class AddDormitoryViewModel: ObservableObject {
    private var campusCardHelper: CampusCardHelper
    private var dorms: [Dorm]

    @Published var isShowingAddDormSheet: Bool {
        didSet {
            isShowingAddDormSheetBinding.wrappedValue = isShowingAddDormSheet
        }
    }

    private var isShowingAddDormSheetBinding: Binding<Bool>

    @Published var isShowingError: Bool = false
    @Published var errorMessage: String = ""

    @Published var selectedCampus: CampusCardHelper.Campus = .jinpenling
    @Published var selectedBuildingID: String = ""
    @Published var room: String = ""

    @Published var buildings: [CampusCardHelper.Campus: [CampusCardHelper.Building]] = [:]
    @Published var isBuildingsLoading: Bool = false

    init(dorms: [Dorm], isShowingAddDormitorySheetBinding: Binding<Bool>) {
        self.campusCardHelper = CampusCardHelper()
        self.dorms = dorms
        self.isShowingAddDormSheet = isShowingAddDormitorySheetBinding.wrappedValue
        self.isShowingAddDormSheetBinding = isShowingAddDormitorySheetBinding
    }

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

        Task {
            do {
                let realm = try await Realm()
                try realm.write {
                    realm.add(dorm)
                }
                isShowingAddDormSheet = false
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }
}
