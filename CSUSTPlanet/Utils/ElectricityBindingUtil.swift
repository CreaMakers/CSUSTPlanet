//
//  ElectricityBindingUtil.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/31.
//

import Alamofire
import Foundation
import OSLog
import SwiftData

enum ElectricityBindingUtilError: Error, LocalizedError {
    case syncFailed(reason: String)

    var errorDescription: String? {
        switch self {
        case .syncFailed(let reason):
            return "定时查询绑定失败: \(reason)"
        }
    }
}

@MainActor
enum ElectricityBindingUtil {
    static func sync() async {
        Logger.electricityBindingUtil.debug("开始同步电量通知绑定")
        try? await syncThrows()
    }

    static func syncThrows() async throws {
        let deviceToken = try await NotificationManager.shared.getToken().hexString

        Logger.electricityBindingUtil.debug("获取到设备 token 和学号")

        var syncList: ElectricityBindingSyncListDTO

        let descriptor = FetchDescriptor<Dorm>()
        let dorms = try SharedModelUtil.mainContext.fetch(descriptor)

        let bindings: [ElectricityBindingSyncDTO]

        if GlobalManager.shared.isNotificationEnabled {
            Logger.electricityBindingUtil.debug("通知已启用，开始同步绑定")
            bindings = dorms.compactMap { dorm in
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
        } else {
            Logger.electricityBindingUtil.debug("未启用通知，同步空列表")
            bindings = []
        }
        syncList = ElectricityBindingSyncListDTO(
            studentId: AuthManager.shared.ssoProfile?.userAccount ?? "",
            deviceToken: deviceToken,
            bindings: bindings
        )

        try await updateSyncList(syncList)
    }

    private static func updateSyncList(_ syncList: ElectricityBindingSyncListDTO) async throws {
        let response = await AF.request("\(Constants.backendHost)/electricity-bindings/sync", method: .post, parameters: syncList, encoder: .json).serializingData().response
        guard let httpResponse = response.response else {
            throw ElectricityBindingUtilError.syncFailed(reason: "无响应")
        }
        guard httpResponse.statusCode == 204 else {
            if let data: Data = response.data {
                let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                throw ElectricityBindingUtilError.syncFailed(reason: errorResponse.reason)
            } else {
                throw ElectricityBindingUtilError.syncFailed(reason: "未知错误")
            }
        }
        Logger.electricityBindingUtil.debug("同步绑定成功")
    }
}
