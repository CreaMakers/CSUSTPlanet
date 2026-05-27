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
    @ObservationIgnored let campusCardHelper = CampusCardHelper()

    var isAddDormSheetPresented: Bool = false
    var isNotificationDeniedAlertPresented: Bool = false
    var isSchedulingDorm: Bool = false
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

    func addDorm(building: CampusCardHelper.Building, room: String) {
        guard let pool = DatabaseManager.shared.pool else { return }

        do {
            try pool.write { db in
                let duplicated =
                    try DormGRDB
                    .filter(DormGRDB.Columns.room == room)
                    .filter(DormGRDB.Columns.buildingID == building.id)
                    .fetchOne(db) != nil
                if duplicated {
                    errorToast.show(message: "该宿舍信息已存在")
                    return
                }

                var dorm = DormGRDB(
                    id: nil,
                    room: room,
                    buildingID: building.id,
                    buildingName: building.name,
                    // TODO: Need to fix
                    campusID: building.campus.rawValue,
                    campusName: building.campus.rawValue,
                    isFavorite: false,
                    lastFetchDate: nil,
                    lastFetchElectricity: nil,
                    scheduleHour: nil,
                    scheduleMinute: nil
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
        guard let campus = CampusCardHelper.Campus(rawValue: dorm.campusName) else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        guard !queryingDormIDs.contains(dormID) else { return }
        queryingDormIDs.insert(dormID)
        defer { queryingDormIDs.remove(dormID) }

        let building = CampusCardHelper.Building(name: dorm.buildingName, id: dorm.buildingID, campus: campus)
        // TODO: Need to fix
        let room = CampusCardHelper.Room(name: dorm.room, id: "", building: building)

        do {
            let electricity = try await campusCardHelper.getElectricity(room: room)
            try await pool.write { db in try DormGRDB.updateElectricity(dormID: dormID, electricity: electricity, in: db) }
            WidgetTimelineRefreshHelper.reloadDormElectricity()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func canConfigureSchedule(for dorm: DormGRDB) -> Bool {
        guard dorm.hasFetchedElectricity else {
            errorToast.show(message: "请先成功查询一次宿舍电量后再配置定时通知")
            return false
        }
        return true
    }

    func configureSchedule(for dorm: DormGRDB, hour: Int, minute: Int) async {
        guard let dormID = dorm.id else { return }
        guard canConfigureSchedule(for: dorm) else { return }

        await performScheduleUpdate(requiresNotificationPermission: true) { db in
            try DormGRDB.updateSchedule(dormID: dormID, hour: hour, minute: minute, in: db)
        }
    }

    func cancelSchedule(for dorm: DormGRDB) async {
        guard let dormID = dorm.id else { return }

        await performScheduleUpdate(requiresNotificationPermission: false) { db in
            try DormGRDB.clearSchedule(dormID: dormID, in: db)
        }
    }

    private func performScheduleUpdate(requiresNotificationPermission: Bool, dbAction: @escaping (Database) throws -> Void) async {
        guard let pool = DatabaseManager.shared.pool else { return }

        guard !isSchedulingDorm else { return }
        isSchedulingDorm = true
        defer { isSchedulingDorm = false }

        do {
            guard let authToken = PlanetAuthService.shared.authToken else {
                errorToast.show(message: "需要登录账号以设置宿舍电量定时通知")
                return
            }
            guard let deviceToken = NotificationManager.shared.token else {
                errorToast.show(message: "无法获取设备通知令牌")
                return
            }
            let permissionStatus = NotificationManager.shared.permissionStatus ?? .requestable

            let syncPermissionStatus: NotificationPermissionStatus
            if requiresNotificationPermission {
                switch permissionStatus {
                case .authorized:
                    syncPermissionStatus = .authorized
                case .denied:
                    isNotificationDeniedAlertPresented = true
                    return
                case .requestable:
                    guard try await NotificationManager.shared.requestPermission() else {
                        isNotificationDeniedAlertPresented = true
                        return
                    }
                    syncPermissionStatus = NotificationManager.shared.permissionStatus ?? .denied
                }
            } else {
                syncPermissionStatus = permissionStatus
            }

            try await pool.write { db in
                try dbAction(db)
            }

            try await PlanetTaskService.shared.sync(permissionStatus: syncPermissionStatus, deviceToken: deviceToken, authToken: authToken)

        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}
