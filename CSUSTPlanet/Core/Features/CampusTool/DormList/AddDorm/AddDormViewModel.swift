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

    var selectedCampus: CampusCardHelper.Campus = .jinpenling {
        didSet {
            if oldValue != selectedCampus {
                buildings = []
                selectedBuilding = nil
                rooms = []
                selectedRoom = nil
                Task { await loadBuildings() }
            }
        }
    }
    var selectedBuilding: CampusCardHelper.Building? = nil {
        didSet {
            if oldValue != selectedBuilding {
                rooms = []
                selectedRoom = nil
                Task { await loadRooms() }
            }
        }
    }
    var selectedRoom: CampusCardHelper.Room? = nil

    var buildings: [CampusCardHelper.Building] = []
    var rooms: [CampusCardHelper.Room] = []

    @ObservationIgnored var isInitial = true

    func loadInitial() async {
        guard isInitial else { return }
        isInitial = false
        await loadBuildings()
    }

    func loadBuildings() async {
        do {
            buildings = try await ElectricityUtil.getBuildings(selectedCampus, useCache: false).sorted { $0.name < $1.name }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func loadRooms() async {
        guard let selectedBuilding else {
            return
        }

        do {
            rooms = try await ElectricityUtil.getRooms(selectedBuilding, useCache: false).sorted { $0.name < $1.name }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}

extension CampusCardHelper.Building: @retroactive Identifiable {}
extension CampusCardHelper.Room: @retroactive Identifiable {}
