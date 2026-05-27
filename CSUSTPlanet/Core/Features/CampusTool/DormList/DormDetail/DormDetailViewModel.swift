//
//  DormDetailViewModel.swift
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
final class DormDetailViewModel: Hashable {
    @ObservationIgnored let campusCardHelper = CampusCardHelper()

    var dorm: DormGRDB
    var sortedRecords: [ElectricityRecordGRDB] = []
    var chartRecords: [ElectricityRecordGRDB] = []
    var chartYDomain: ClosedRange<Double> = 0...2
    var exhaustionInfo: String?
    var errorToast: ToastState = .errorTitle
    var isQueryingElectricity: Bool = false
    var isDeleteAllRecordsAlertPresented: Bool = false
    var isScheduleConfigSheetPresented: Bool = false
    var isCancelScheduleAlertPresented: Bool = false
    var isNotificationDeniedAlertPresented: Bool = false
    var isSchedulingDorm: Bool = false

    @ObservationIgnored private var dormObserver: (any DatabaseCancellable)?
    @ObservationIgnored private var recordsObserver: (any DatabaseCancellable)?
    @ObservationIgnored private var ipcCancellable: AnyCancellable?

    @ObservationIgnored var isInitial: Bool = true

    init(dorm: DormGRDB) {
        self.dorm = dorm
    }

    func loadInitial() async {
        guard isInitial else { return }
        isInitial = false
        startObservation()
    }

    func toggleFavorite() {
        guard let dormID = dorm.id else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        do {
            try pool.write { db in try DormGRDB.toggleFavorite(dormID: dormID, in: db) }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func queryElectricity() async {
        guard let dormID = dorm.id else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        guard !isQueryingElectricity else { return }
        isQueryingElectricity = true
        defer { isQueryingElectricity = false }

        do {
            let electricity = try await ElectricityUtil.getElectricity(AuthManager.shared.campusCardHelper, campusName: dorm.campusName, buildingName: dorm.buildingName, roomName: dorm.room)
            try await pool.write { db in try DormGRDB.updateElectricity(dormID: dormID, electricity: electricity, in: db) }
            WidgetTimelineRefreshHelper.reloadDormElectricity()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func deleteRecord(_ record: ElectricityRecordGRDB) {
        guard let dormID = dorm.id else { return }
        guard let recordID = record.id else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        do {
            try pool.write { db in try DormGRDB.deleteElectricityRecord(dormID: dormID, recordID: recordID, in: db) }
            // 移除手动 refreshSortedRecords()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func deleteAllRecords() {
        guard let dormID = dorm.id else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        do {
            try pool.write { db in try DormGRDB.deleteAllElectricityRecords(dormID: dormID, in: db) }
            WidgetTimelineRefreshHelper.reloadDormElectricity()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func canConfigureSchedule() -> Bool {
        guard dorm.hasFetchedElectricity else {
            errorToast.show(message: "请先成功查询一次宿舍电量后再配置定时通知")
            return false
        }
        return true
    }

    func configureSchedule(hour: Int, minute: Int) async {
        guard let dormID = dorm.id else { return }
        guard canConfigureSchedule() else { return }

        await performScheduleUpdate(requiresNotificationPermission: true) { db in
            try DormGRDB.updateSchedule(dormID: dormID, hour: hour, minute: minute, in: db)
        }
    }

    func cancelSchedule() async {
        guard let dormID = dorm.id else { return }

        await performScheduleUpdate(requiresNotificationPermission: false) { db in
            try DormGRDB.clearSchedule(dormID: dormID, in: db)
        }
    }

    private func startObservation() {
        setupIPCObservationIfNeeded()
        restartGRDBObservations()
    }

    private func setupIPCObservationIfNeeded() {
        guard ipcCancellable == nil else { return }

        ipcCancellable = GRDBIPCNotifier.shared.dbChangedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.restartGRDBObservations()
            }
    }

    private func restartGRDBObservations() {
        observeDormDetail()
        observeRecords()
    }

    private func observeDormDetail() {
        dormObserver?.cancel()
        guard let dormID = dorm.id else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        let observation = ValueObservation.tracking { db in
            try DormGRDB.fetchOne(db, key: dormID)
        }

        dormObserver = observation.start(
            in: pool,
            scheduling: .immediate,
            onError: { [weak self] error in
                Task { @MainActor in self?.errorToast.show(message: error.localizedDescription) }
            },
            onChange: { [weak self] latestDorm in
                guard let latestDorm else { return }
                Task { @MainActor in withAnimation { self?.dorm = latestDorm } }
            }
        )
    }

    private func observeRecords() {
        recordsObserver?.cancel()
        guard let dormID = dorm.id else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        struct ProcessedDetailData {
            let sortedRecords: [ElectricityRecordGRDB]
            let chartRecords: [ElectricityRecordGRDB]
            let chartYDomain: ClosedRange<Double>
            let exhaustionInfo: String?
        }

        let observation = ValueObservation.tracking { db in
            let recentStartDate = ElectricityUtil.recentRecordsStartDate()
            return
                try ElectricityRecordGRDB
                .filter(ElectricityRecordGRDB.Columns.dormID == dormID)
                .filter(ElectricityRecordGRDB.Columns.date >= recentStartDate)
                .order(ElectricityRecordGRDB.Columns.date.desc)
                .fetchAll(db)
        }
        .map { records -> ProcessedDetailData in
            let sortedRecords = records
            let recordsAscending = Array(records.reversed())
            let chartRecords = ElectricityUtil.downsample(from: recordsAscending, to: 150)
            let exhaustionInfo = ElectricityUtil.getExhaustionInfo(from: recordsAscending)

            return ProcessedDetailData(
                sortedRecords: sortedRecords,
                chartRecords: chartRecords,
                chartYDomain: ElectricityUtil.chartYDomain(for: chartRecords),
                exhaustionInfo: exhaustionInfo
            )
        }

        recordsObserver = observation.start(
            in: pool,
            scheduling: .immediate,
            onError: { [weak self] error in
                Task { @MainActor in self?.errorToast.show(message: error.localizedDescription) }
            },
            onChange: { [weak self] data in
                Task { @MainActor in
                    withAnimation {
                        self?.sortedRecords = data.sortedRecords
                        self?.chartRecords = data.chartRecords
                        self?.chartYDomain = data.chartYDomain
                        self?.exhaustionInfo = data.exhaustionInfo
                    }
                }
            }
        )
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

    nonisolated static func == (lhs: DormDetailViewModel, rhs: DormDetailViewModel) -> Bool {
        return lhs === rhs
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
