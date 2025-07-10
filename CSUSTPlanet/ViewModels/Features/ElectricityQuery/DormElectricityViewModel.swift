//
//  DormRowViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/10.
//

import CSUSTKit
import Foundation
import SwiftData
import SwiftUI

@MainActor
class DormElectricityViewModel: ObservableObject {
    private var campusCardHelper: CampusCardHelper
    private var modelContext: ModelContext

    private var dormBinding: Binding<Dorm> {
        Binding(
            get: { self.dorm },
            set: { newValue in
                self.dorm = newValue
                try? self.modelContext.save()
            }
        )
    }

    @Published var dorm: Dorm

    @Published var isShowingErrorAlert: Bool = false
    @Published var errorMessage: String = ""

    @Published var isQueryingElectricity: Bool = false
    @Published var isConfirmationDialogPresented: Bool = false

    private let dateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        return dateFormatter
    }()

    init(modelContext: ModelContext, dorm: Dorm) {
        campusCardHelper = CampusCardHelper()
        self.modelContext = modelContext
        self.dorm = dorm
    }

    func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }

    func handleQueryElectricity() {
        isQueryingElectricity = true
        guard let campus = Campus(rawValue: dorm.campusName) else {
            errorMessage = "无效的校区ID"
            isShowingErrorAlert = true
            return
        }
        let building = Building(name: dorm.buildingName, id: dorm.buildingID, campus: campus)
        Task {
            do {
                defer {
                    isQueryingElectricity = false
                }
                let electricity = try await campusCardHelper.getElectricity(building: building, room: dorm.room)
                if let lastRecord = getLastRecord() {
                    if lastRecord.electricity == electricity {
                        return
                    }
                }

                let record = ElectricityRecord(electricity: electricity, date: Date(), dorm: dorm)
                modelContext.insert(record)
            } catch {
                errorMessage = error.localizedDescription
                isShowingErrorAlert = true
            }
        }
    }

    func getLastRecord() -> ElectricityRecord? {
        return dorm.records.sorted { $0.date > $1.date }.first
    }

    func deleteDorm() {
        modelContext.delete(dorm)
    }

    func deleteRecord(record: ElectricityRecord) {
        modelContext.delete(record)
    }
}
