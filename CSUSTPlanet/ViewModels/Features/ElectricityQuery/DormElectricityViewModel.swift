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

    func handleNotificationSettings(scheduleHour: Int, scheduleMinute: Int) {
        self.scheduleHour = scheduleHour
        self.scheduleMinute = scheduleMinute
        Task {
            do {
                let granted = try await NotificationHelper.shared.requestAuthorization()
                guard granted else {
                    errorMessage = "未能获取通知权限，请在设置中开启"
                    isShowingError = true
                    return
                }

                let token = try await NotificationHelper.shared.getDeviceToken()

                struct ElectricityBindingDTO: Codable {
                    let id: String?
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
                let request = ElectricityBindingDTO(
                    id: nil,
                    studentId: studentId,
                    deviceToken: token,
                    campus: dorm.campusName,
                    building: dorm.buildingName,
                    room: dorm.room,
                    scheduleHour: scheduleHour,
                    scheduleMinute: scheduleMinute
                )

                struct ErrorResponse: Decodable {
                    let reason: String
                    let error: Bool
                }

                let response = await AF.request("https://api.csustplanet.zhelearn.com/electricity-bindings", method: .post, parameters: request, encoder: .json).serializingData().response

                guard let httpResponse = response.response else {
                    errorMessage = "网络请求失败"
                    isShowingError = true
                    return
                }

                if httpResponse.statusCode != 200 {
                    do {
                        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: response.data ?? Data())
                        errorMessage = errorResponse.reason
                    } catch {
                        errorMessage = "服务器返回错误"
                    }
                    isShowingError = true
                    return
                }
                let successResponse = try JSONDecoder().decode(ElectricityBindingDTO.self, from: response.data ?? Data())
                debugPrint(successResponse)
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }
}
