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
    static func sync(studentId: String, deviceToken: String) async throws {
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
        let syncList = ElectricityBindingSyncListDTO(
            studentId: studentId,
            deviceToken: deviceToken,
            bindings: bindings
        )

        debugPrint("Syncing electricity bindings: \(syncList)")

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
