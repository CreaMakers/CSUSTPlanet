//
//  ElectricityBindingHelper.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/31.
//

import Alamofire
import Foundation
import SwiftData

enum ElectricityBindingHelperError: Error, LocalizedError {
    case syncFailed(reason: String)

    var errorDescription: String? {
        switch self {
        case .syncFailed(let reason):
            return "定时查询绑定失败: \(reason)"
        }
    }
}

@MainActor
class ElectricityBindingHelper {
    static func sync() async {
        debugPrint("ElectricityBindingHelper: Starting sync...")
        try? await syncThrows()
    }

    static func syncThrows() async throws {
        let deviceToken = try await NotificationHelper.shared.getToken().hexString
        guard let studentId = AuthManager.shared.ssoProfile?.userAccount else {
            throw ElectricityBindingHelperError.syncFailed(reason: "未能获取学号，请先登录")
        }

        debugPrint("ElectricityBindingHelper: Fetched device token and student ID")

        var syncList: ElectricityBindingSyncListDTO

        if GlobalVars.shared.isElectricityTermAccepted {
            let descriptor = FetchDescriptor<Dorm>()
            let dorms = try SharedModel.mainContext.fetch(descriptor)

            let bindings: [ElectricityBindingSyncDTO] = dorms.compactMap { dorm in
                guard let scheduleHour = dorm.scheduleHour, let scheduleMinute = dorm.scheduleMinute else {
                    return nil
                }
                return ElectricityBindingSyncDTO(
                    campus: dorm.campusName,
                    building: dorm.buildingName,
                    room: dorm.room,
                    scheduleHour: scheduleHour,
                    scheduleMinute: scheduleMinute
                )
            }
            syncList = ElectricityBindingSyncListDTO(
                studentId: studentId,
                deviceToken: deviceToken,
                bindings: bindings
            )
        } else {
            syncList = ElectricityBindingSyncListDTO(
                studentId: studentId,
                deviceToken: deviceToken,
                bindings: []
            )
        }

        try await updateSyncList(syncList)
    }

    private static func updateSyncList(_ syncList: ElectricityBindingSyncListDTO) async throws {
        let response = await AF.request("\(Constants.backendHost)/electricity-bindings/sync", method: .post, parameters: syncList, encoder: .json).serializingData().response
        guard let httpResponse = response.response else {
            throw ElectricityBindingHelperError.syncFailed(reason: "无响应")
        }
        guard httpResponse.statusCode == 204 else {
            if let data: Data = response.data {
                let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                throw ElectricityBindingHelperError.syncFailed(reason: errorResponse.reason)
            } else {
                throw ElectricityBindingHelperError.syncFailed(reason: "未知错误")
            }
        }
    }
}
