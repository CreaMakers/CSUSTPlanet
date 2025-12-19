//
//  DormRowViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/10.
//

import Alamofire
import CSUSTKit
import Foundation
import SwiftData
import SwiftUI
import WidgetKit

@MainActor
class DormElectricityViewModel: ObservableObject {
    private let campusCardHelper = CampusCardHelper()
    private let modelContext = SharedModelHelper.mainContext

    @Published var isShowingError: Bool = false
    @Published var errorMessage: String = ""

    @Published var isQueryingElectricity: Bool = false

    @Published var isConfirmationDialogPresented: Bool = false
    @Published var isTermsPresented: Bool = false
    @Published var isShowNotificationSettings: Bool = false

    @Published var isScheduleLoading: Bool = false

    private let dateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        return dateFormatter
    }()

    func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }

    func getExhaustionInfo(from records: [ElectricityRecord]?) -> String? {
        guard let records = records, !records.isEmpty else { return nil }
        guard let predictionDate = ElectricityHelper.predictExhaustionDate(from: records) else { return nil }

        let now = Date()
        let interval = predictionDate.timeIntervalSince(now)
        guard interval > 0 else { return nil }

        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if days > 0 {
            return "预计\(days)天后电量耗尽"
        } else if hours > 0 {
            return "预计\(hours)小时后电量耗尽"
        } else {
            return "预计\(minutes)分钟后电量耗尽"
        }
    }

    func removeSchedule(_ dorm: Dorm) {
        guard dorm.scheduleEnabled else { return }
        isScheduleLoading = true
        Task {
            defer {
                isScheduleLoading = false
            }
            do {
                dorm.scheduleHour = nil
                dorm.scheduleMinute = nil
                try await ElectricityBindingHelper.syncThrows()
                try modelContext.save()
            } catch {
                modelContext.rollback()
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func handleQueryElectricity(_ dorm: Dorm) {
        isQueryingElectricity = true
        guard let campus = CampusCardHelper.Campus(rawValue: dorm.campusName) else {
            errorMessage = "无效的校区ID"
            isShowingError = true
            return
        }
        let building = CampusCardHelper.Building(name: dorm.buildingName, id: dorm.buildingID, campus: campus)
        Task {
            do {
                defer {
                    isQueryingElectricity = false
                }
                let electricity = try await campusCardHelper.getElectricity(building: building, room: dorm.room)
                let record = ElectricityRecord(electricity: electricity, date: Date(), dorm: dorm)
                modelContext.insert(record)
                try modelContext.save()

                WidgetCenter.shared.reloadTimelines(ofKind: "DormElectricityWidget")
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func deleteDorm(_ dorm: Dorm) {
        Task {
            do {
                let scheduleEnabled = dorm.scheduleEnabled
                modelContext.delete(dorm)
                if scheduleEnabled {
                    await ElectricityBindingHelper.sync()
                }
                try modelContext.save()
            } catch {
                modelContext.rollback()
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func deleteAllRecords(_ dorm: Dorm) {
        for record in dorm.records ?? [] {
            modelContext.delete(record)
        }
        do {
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }

    func deleteRecord(record: ElectricityRecord) {
        modelContext.delete(record)
        do {
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }

    func handleTermsAgree() {
        isShowNotificationSettings = true
    }

    func handleNotificationSettings(_ dorm: Dorm, scheduleHour: Int, scheduleMinute: Int) {
        Task {
            do {
                dorm.scheduleHour = scheduleHour
                dorm.scheduleMinute = scheduleMinute
                try await ElectricityBindingHelper.syncThrows()
                try modelContext.save()
            } catch {
                modelContext.rollback()
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func toggleFavorite(_ dorm: Dorm) {
        do {
            if dorm.isFavorite {
                dorm.isFavorite = false
            } else {
                let descriptor = FetchDescriptor<Dorm>(predicate: #Predicate { $0.isFavorite == true })
                let favorites = try modelContext.fetch(descriptor)
                for favorite in favorites {
                    favorite.isFavorite = false
                }
                dorm.isFavorite = true
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }
}
