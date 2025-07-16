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

@MainActor
class DormElectricityViewModel: ObservableObject {
    private var campusCardHelper: CampusCardHelper
    private var authManager: AuthManager
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

    @Published var isShowingError: Bool = false
    @Published var errorMessage: String = ""

    @Published var isQueryingElectricity: Bool = false
    @Published var isConfirmationDialogPresented: Bool = false

    @Published var isTermsPresented: Bool = false

    @Published var isShowNotificationSettings: Bool = false

    private var scheduleHour: Int = 0
    private var scheduleMinute: Int = 0

    private let dateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        return dateFormatter
    }()

    init(authManager: AuthManager, modelContext: ModelContext, dorm: Dorm) {
        campusCardHelper = CampusCardHelper()
        self.authManager = authManager
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
            isShowingError = true
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
                isShowingError = true
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

    func handleShowTerms() {
        guard authManager.isLoggedIn else {
            errorMessage = "请先登录"
            isShowingError = true
            return
        }
        if GlobalVars.shared.isElectricityTermAccepted {
            handleTermsAgree()
        } else {
            isTermsPresented = true
        }
    }

    func handleTermsAgree() {
        isTermsPresented = false
        isShowNotificationSettings = true
    }

    func onDeviceToken(token: String) {
        Task {
            struct CreateElectricityBindingRequest: Encodable {
                let studentId: String
                let deviceToken: String
                let campus: String
                let building: String
                let room: String
                let scheduleHour: Int
                let scheduleMinute: Int
            }
            guard let studentId = authManager.ssoProfile?.userAccount else {
                errorMessage = "未能获取学号，请先登录"
                isShowingError = true
                return
            }
            let request = CreateElectricityBindingRequest(
                studentId: studentId,
                deviceToken: token,
                campus: dorm.campusName,
                building: dorm.buildingName,
                room: dorm.room,
                scheduleHour: scheduleHour,
                scheduleMinute: scheduleMinute
            )
            let response = await AF.request("https://api.csustplanet.zhelearn.com/electricity-bindings", method: .post, parameters: request, encoder: .json).serializingData().response

            guard let httpResponse = response.response, httpResponse.statusCode == 201 else {
                errorMessage = "绑定失败，请稍后再试"
                isShowingError = true
                return
            }
            debugPrint("绑定成功")
        }
    }

    func handleNotificationSettings(scheduleHour: Int, scheduleMinute: Int) {
        self.scheduleHour = scheduleHour
        self.scheduleMinute = scheduleMinute
        NotificationHelper.shared.requestAuthorization(onDeviceToken: onDeviceToken, onResult: onResult, onError: onError)
    }

    func onResult(granted: Bool) {
        if !granted {
            DispatchQueue.main.async {
                self.errorMessage = "未能获取通知权限，请在设置中开启"
                self.isShowingError = true
            }
        }
    }

    func onError(error: Error) {
        errorMessage = error.localizedDescription
        isShowingError = true
    }
}
