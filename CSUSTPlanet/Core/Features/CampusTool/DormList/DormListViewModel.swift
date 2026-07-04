//
//  DormListViewModel.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/21.
//

import CSUSTKit
import Combine
import Foundation
import GRDB
import SwiftUI

@MainActor
@Observable
final class DormListViewModel {
    var isAddDormSheetPresented: Bool = false
    var dorms: [DormGRDB] = []
    var errorToast: ToastState = .errorTitle
    var queryingDormIDs: Set<Int64> = []
    var targetDeleteDorm: DormGRDB?
    var exhaustionInfoMap: [Int64: String] = [:]

    @ObservationIgnored private var listObserver: (any DatabaseCancellable)?
    @ObservationIgnored private var ipcCancellable: AnyCancellable?

    @ObservationIgnored var isInitial: Bool = true
    @ObservationIgnored var isFirstObservation: Bool = true
    var isLoading: Bool = true

    func loadInitial() async {
        guard isInitial else { return }
        isInitial = false
        observeList()
    }

    func observeList() {
        setupIPCObservationIfNeeded()
        restartListObservation()
    }

    private func setupIPCObservationIfNeeded() {
        guard ipcCancellable == nil else { return }

        ipcCancellable = GRDBIPCNotifier.shared.dbChangedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.restartListObservation()
            }
    }

    private func restartListObservation() {
        listObserver?.cancel()
        guard let pool = DatabaseManager.shared.pool else { return }

        let observation = ValueObservation.tracking { db -> ([DormGRDB], [ElectricityRecordGRDB]) in
            let dorms = try DormGRDB.order(DormGRDB.Columns.id.desc).fetchAll(db)
            let recentStartDate = ElectricityUtil.recentRecordsStartDate()
            let records =
                try ElectricityRecordGRDB
                .filter(ElectricityRecordGRDB.Columns.date >= recentStartDate)
                .order(ElectricityRecordGRDB.Columns.date.asc)
                .fetchAll(db)
            return (dorms, records)
        }
        .map { (dorms, records) -> ([DormGRDB], [Int64: String]) in
            let recordsByDormID = Dictionary(grouping: records, by: { $0.dormID })
            var infoMap: [Int64: String] = [:]
            infoMap.reserveCapacity(dorms.count)

            for dorm in dorms {
                guard let dormID = dorm.id else { continue }
                let dormRecords = recordsByDormID[dormID] ?? []
                infoMap[dormID] = ElectricityUtil.getExhaustionInfo(from: dormRecords)
            }
            return (dorms, infoMap)
        }

        listObserver = observation.start(
            in: pool,
            scheduling: .immediate,
            onError: { [weak self] error in
                Task { @MainActor in self?.errorToast.show(message: error.localizedDescription) }
            },
            onChange: { [weak self] result in
                Task { @MainActor in
                    guard let self = self else { return }
                    if self.isFirstObservation {
                        self.isFirstObservation = false
                        self.dorms = result.0
                        self.exhaustionInfoMap = result.1
                        self.isLoading = false
                    } else {
                        withAnimation {
                            self.dorms = result.0
                            self.exhaustionInfoMap = result.1
                        }
                    }
                }
            }
        )
    }

    func addDorm(room: CampusCardHelper.Room) {
        guard let pool = DatabaseManager.shared.pool else { return }
        let building = room.building
        let campus = building.campus

        do {
            try pool.write { db in
                let duplicated =
                    try DormGRDB
                    .filter(DormGRDB.Columns.room == room.name)
                    .filter(DormGRDB.Columns.buildingName == building.name)
                    .filter(DormGRDB.Columns.campusName == campus.rawValue)
                    .fetchOne(db) != nil
                if duplicated {
                    errorToast.show(message: "该宿舍信息已存在")
                    return
                }

                var dorm = DormGRDB(
                    id: nil,
                    room: room.name,
                    buildingName: building.name,
                    campusName: building.campus.rawValue,
                    isFavorite: false,
                    lastFetchDate: nil,
                    lastFetchElectricity: nil
                )
                try dorm.insert(db)
            }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func deleteDorm(_ dorm: DormGRDB) {
        guard let dormID = dorm.id else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        do {
            try pool.write { db in _ = try DormGRDB.deleteOne(db, key: dormID) }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func toggleFavorite(_ dorm: DormGRDB) {
        guard let dormID = dorm.id else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        do {
            try pool.write { db in try DormGRDB.toggleFavorite(dormID: dormID, in: db) }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func isQuerying(_ dorm: DormGRDB) -> Bool {
        guard let dormID = dorm.id else { return false }
        return queryingDormIDs.contains(dormID)
    }

    func queryElectricity(for dorm: DormGRDB) async {
        guard let dormID = dorm.id else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        guard !queryingDormIDs.contains(dormID) else { return }
        queryingDormIDs.insert(dormID)
        defer { queryingDormIDs.remove(dormID) }

        do {
            let electricity = try await ElectricityUtil.getElectricity(
                AuthManager.shared.campusCardHelper,
                campusName: dorm.campusName,
                buildingName: dorm.buildingName,
                roomName: dorm.room,
                retryProvider: AuthManager.shared
            )
            try await pool.write { db in try DormGRDB.updateElectricity(dormID: dormID, electricity: electricity, in: db) }
            WidgetTimelineRefreshHelper.reloadDormElectricity()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}
