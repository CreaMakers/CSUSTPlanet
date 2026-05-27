//
//  DormOverviewViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import Combine
import Foundation
import GRDB
import SwiftUI

@MainActor
@Observable
final class DormOverviewViewModel {
    private struct ProcessedDormOverviewData {
        let dorm: DormGRDB?
        let exhaustionInfo: String?
        let chartRecords: [ElectricityRecordGRDB]
        let chartYDomain: ClosedRange<Double>
    }

    @ObservationIgnored let campusCardHelper = CampusCardHelper()

    var primaryDorm: DormGRDB?
    var electricityExhaustionInfo: String?
    var chartRecords: [ElectricityRecordGRDB] = []
    var chartYDomain: ClosedRange<Double> = 0...2
    var isQueryingElectricity: Bool = false

    var lastFetchDate: Date? {
        primaryDorm?.lastFetchDate
    }

    @ObservationIgnored var isFirstObservation = true

    @ObservationIgnored private var dormObserver: (any DatabaseCancellable)?
    @ObservationIgnored private var ipcCancellable: AnyCancellable?

    func onAppear() {
        setupIPCObservationIfNeeded()
        observePrimaryDorm()
    }

    func queryElectricity() async {
        guard let dorm = primaryDorm else { return }
        guard let dormID = dorm.id else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        guard !isQueryingElectricity else { return }
        isQueryingElectricity = true
        defer { isQueryingElectricity = false }

        do {
            let electricity = try await ElectricityUtil.getElectricity(AuthManager.shared.campusCardHelper, campusName: dorm.campusName, buildingName: dorm.buildingName, roomName: dorm.room)
            try await pool.write { db in try DormGRDB.updateElectricity(dormID: dormID, electricity: electricity, in: db) }
            WidgetTimelineRefreshHelper.reloadDormElectricity()
        } catch {}
    }

    private func setupIPCObservationIfNeeded() {
        guard ipcCancellable == nil else { return }

        ipcCancellable = GRDBIPCNotifier.shared.dbChangedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.observePrimaryDorm()
            }
    }

    private func observePrimaryDorm() {
        dormObserver?.cancel()
        guard let pool = DatabaseManager.shared.pool else {
            primaryDorm = nil
            electricityExhaustionInfo = nil
            chartRecords = []
            chartYDomain = 0...2
            return
        }

        let observation = ValueObservation.tracking { db -> (DormGRDB?, [ElectricityRecordGRDB]) in
            let favoriteDorm =
                try DormGRDB
                .filter(DormGRDB.Columns.isFavorite == true)
                .fetchOne(db)

            let dorm = try favoriteDorm ?? DormGRDB.order(DormGRDB.Columns.id.asc).fetchOne(db)
            guard let dormID = dorm?.id else { return (dorm, []) }
            let recentStartDate = ElectricityUtil.recentRecordsStartDate()

            let records =
                try ElectricityRecordGRDB
                .filter(ElectricityRecordGRDB.Columns.dormID == dormID)
                .filter(ElectricityRecordGRDB.Columns.date >= recentStartDate)
                .order(ElectricityRecordGRDB.Columns.date.asc)
                .fetchAll(db)

            return (dorm, records)
        }
        .map { (dorm, records) -> ProcessedDormOverviewData in
            let sampledRecords = ElectricityUtil.downsample(from: records, to: 80)

            return ProcessedDormOverviewData(
                dorm: dorm,
                exhaustionInfo: ElectricityUtil.getExhaustionInfo(from: records),
                chartRecords: sampledRecords,
                chartYDomain: ElectricityUtil.chartYDomain(for: sampledRecords)
            )
        }

        dormObserver = observation.start(
            in: pool,
            scheduling: .immediate,
            onError: { [weak self] _ in
                Task { @MainActor in
                    self?.primaryDorm = nil
                    self?.electricityExhaustionInfo = nil
                    self?.chartRecords = []
                    self?.chartYDomain = 0...2
                }
            },
            onChange: { [weak self] data in
                guard let self = self else { return }
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    if self.isFirstObservation {
                        self.primaryDorm = data.dorm
                        self.electricityExhaustionInfo = data.exhaustionInfo
                        self.chartRecords = data.chartRecords
                        self.chartYDomain = data.chartYDomain
                        self.isFirstObservation = false
                    } else {
                        withAnimation {
                            self.primaryDorm = data.dorm
                            self.electricityExhaustionInfo = data.exhaustionInfo
                            self.chartRecords = data.chartRecords
                            self.chartYDomain = data.chartYDomain
                        }
                    }
                }
            }
        )
    }
}
