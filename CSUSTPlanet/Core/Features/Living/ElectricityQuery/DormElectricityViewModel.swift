//
//  DormRowViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/10.
//

import Alamofire
import CSUSTKit
import Foundation
import RealmSwift
import SwiftUI
import WidgetKit

@MainActor
class DormElectricityViewModel: ObservableObject {
    private var campusCardHelper = CampusCardHelper()

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

    func loadSchedule(_ dorm: Dorm) {
        guard MMKVManager.shared.isElectricityTermAccepted else {
            return
        }
        guard let scheduleId = dorm.schedule?.id else {
            return
        }
        isScheduleLoading = true
        Task {
            defer {
                isScheduleLoading = false
            }
            do {
                let deviceToken = try await NotificationHelper.shared.getDeviceToken()
                let response = await AF.request("https://api.csustplanet.zhelearn.com/electricity-bindings/\(deviceToken)/\(scheduleId)", method: .get).serializingData().response

                guard let httpResponse = response.response else {
                    errorMessage = "网络请求失败"
                    isShowingError = true
                    return
                }

                guard httpResponse.statusCode == 200 else {
                    do {
                        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: response.data ?? Data())
                        errorMessage = errorResponse.reason
                    } catch {
                        errorMessage = "服务器返回错误"
                    }
                    let realm = try await Realm()
                    try realm.write {
                        dorm.schedule = nil
                    }
                    // try modelContext.save()
                    isShowingError = true
                    return
                }

                let successResponse = try JSONDecoder().decode(ElectricityBindingDTO.self, from: response.data ?? Data())
                guard let id = successResponse.id else { return }
                let realm = try await Realm()
                try realm.write {
                    dorm.schedule = DormSchedule(id: id, hour: successResponse.scheduleHour, minute: successResponse.scheduleMinute)
                }
                // try modelContext.save()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func removeSchedule(_ dorm: Dorm) -> Task<Void, Never> {
        guard let scheduleId = dorm.schedule?.id else {
            return Task {}
        }
        isScheduleLoading = true
        return Task {
            defer {
                isScheduleLoading = false
            }
            do {
                let deviceToken = try await NotificationHelper.shared.getDeviceToken()
                let response = await AF.request("https://api.csustplanet.zhelearn.com/electricity-bindings/\(deviceToken)/\(scheduleId)", method: .delete).serializingData().response

                guard let httpResponse = response.response else {
                    errorMessage = "网络请求失败"
                    isShowingError = true
                    return
                }

                guard httpResponse.statusCode == 200 else {
                    do {
                        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: response.data ?? Data())
                        errorMessage = errorResponse.reason
                    } catch {
                        errorMessage = "服务器返回错误"
                    }
                    isShowingError = true
                    return
                }

                let realm = try await Realm()
                try realm.write {
                    dorm.schedule = nil
                }
                // try modelContext.save()
            } catch {
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
                if let lastRecord = dorm.latestRecord {
                    if lastRecord.electricity == electricity {
                        return
                    }
                }

                let record = ElectricityRecord(electricity: electricity, date: .now)

                let realm = try await Realm()
                guard let dorm = realm.object(ofType: Dorm.self, forPrimaryKey: dorm.id) else { return }
                try realm.write {
                    dorm.records.append(record)
                }

                WidgetCenter.shared.reloadTimelines(ofKind: "DormElectricityWidget")
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func deleteDorm(_ dormId: ObjectId) {
        do {
            let realm = try Realm()
            guard let dormToDelete = realm.object(ofType: Dorm.self, forPrimaryKey: dormId) else { return }

            if dormToDelete.schedule != nil {
                Task {
                    await removeSchedule(dormToDelete).value
                }
            }

            try realm.write {
                realm.delete(dormToDelete.records)
                realm.delete(dormToDelete)
            }
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }

    func deleteAllRecords(_ dorm: Dorm) {
        Task {
            do {
                let realm = try await Realm()
                try realm.write {
                    realm.delete(dorm.records)
                }
                // try modelContext.save()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func deleteRecord(record: ElectricityRecord) {
        Task {
            do {
                let realm = try await Realm()
                try realm.write {
                    realm.delete(record)
                }
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func handleShowTerms() {
        guard AuthManager.shared.isLoggedIn else {
            errorMessage = "请先登录"
            isShowingError = true
            return
        }
        if MMKVManager.shared.isElectricityTermAccepted {
            handleTermsAgree()
        } else {
            isTermsPresented = true
        }
    }

    func handleTermsAgree() {
        isTermsPresented = false
        isShowNotificationSettings = true
    }

    func handleNotificationSettings(scheduleHour: Int, scheduleMinute: Int, dorm: Dorm) {
        Task {
            do {
                let granted = try await NotificationHelper.shared.requestAuthorization()
                guard granted else {
                    errorMessage = "未能获取通知权限，请在设置中开启"
                    isShowingError = true
                    return
                }

                let token = try await NotificationHelper.shared.getDeviceToken()

                guard let studentId = AuthManager.shared.ssoProfile?.userAccount else {
                    errorMessage = "未能获取学号，请先登录"
                    isShowingError = true
                    return
                }

                let environment = AppEnvironmentHelper.environment
                let request = ElectricityBindingDTO(
                    id: nil,
                    studentId: studentId,
                    deviceToken: token,
                    isDebug: environment == .debug,
                    campus: dorm.campusName,
                    building: dorm.buildingName,
                    room: dorm.room,
                    scheduleHour: scheduleHour,
                    scheduleMinute: scheduleMinute
                )

                let response = await AF.request("https://api.csustplanet.zhelearn.com/electricity-bindings", method: .post, parameters: request, encoder: .json).serializingData().response

                guard let httpResponse = response.response else {
                    errorMessage = "网络请求失败"
                    isShowingError = true
                    return
                }

                guard httpResponse.statusCode == 200 else {
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
                guard let id = successResponse.id else { return }
                let realm = try await Realm()
                try realm.write {
                    dorm.schedule = DormSchedule(id: id, hour: scheduleHour, minute: scheduleMinute)
                }
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    struct ElectricityBindingDTO: Codable {
        let id: String?
        let studentId: String
        let deviceToken: String
        let isDebug: Bool
        let campus: String
        let building: String
        let room: String
        let scheduleHour: Int
        let scheduleMinute: Int
    }

    struct ErrorResponse: Decodable {
        let reason: String
        let error: Bool
    }
}
