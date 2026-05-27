//
//  ElectricityBackgroundTask.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/1/17.
//

#if os(iOS)

import BackgroundTasks
import CSUSTKit
import Foundation
import GRDB
import OSLog
import UserNotifications

struct ElectricityBackgroundTask: BackgroundTaskProvider {
    let identifier: String = "electricity"

    let title: String = "查询宿舍电量"
    let description: String = "在后台查询当前收藏宿舍电量，查询后发送当前电量通知"

    func perform() async -> Bool {
        Logger.electricityBackgroundTask.debug("开始后台获取电量任务: \(self.identifier)")

        do {
            guard let pool = DatabaseManager.shared.pool else {
                Logger.electricityBackgroundTask.error("数据库不可用，跳过电量查询")
                return false
            }

            let targetDorm: DormGRDB? = try await pool.read { db in
                if let favoriteDorm =
                    try DormGRDB
                    .filter(DormGRDB.Columns.isFavorite == true)
                    .fetchOne(db)
                {
                    return favoriteDorm
                }

                Logger.electricityBackgroundTask.debug("未找到 Favorite 宿舍，尝试获取列表中的第一个宿舍")
                return try DormGRDB.fetchOne(db)
            }

            guard let dorm = targetDorm else {
                Logger.electricityBackgroundTask.debug("数据库中没有任何宿舍，跳过电量查询")
                return true
            }

            let mode: ConnectionMode = MMKVHelper.GlobalManager.isWebVPNModeEnabled ? .webVpn : .direct
            let session = CookieHelper.shared.session

            let ssoHelper = SSOHelper(mode: mode, session: session)
            let campusCardHelper = CampusCardHelper(mode: mode, session: session)

            campusCardHelper.token = KeychainUtil.campusCardToken

            if await !campusCardHelper.isLoggedIn() {
                if await ssoHelper.isLoggedIn() {
                    let (_, ticket) = try await ssoHelper.loginToCampusCard()
                    try await campusCardHelper.syncToken(ticket: ticket)

                    CookieHelper.shared.save()
                    KeychainUtil.campusCardToken = campusCardHelper.token
                } else {
                    guard let username = KeychainUtil.ssoUsername, let password = KeychainUtil.ssoPassword else {
                        return false
                    }
                    let loginForm = try await ssoHelper.getLoginForm()
                    try await ssoHelper.login(loginForm: loginForm, username: username, password: password, captcha: nil)

                    let (_, ticket) = try await ssoHelper.loginToCampusCard()
                    try await campusCardHelper.syncToken(ticket: ticket)

                    CookieHelper.shared.save()
                    KeychainUtil.campusCardToken = campusCardHelper.token
                }
            }

            var fetchedElectricity: Double? = nil

            for i in 1...3 {
                try Task.checkCancellation()
                do {
                    fetchedElectricity = try await ElectricityUtil.getElectricity(campusCardHelper, campusName: dorm.campusName, buildingName: dorm.buildingName, roomName: dorm.room)
                    Logger.electricityBackgroundTask.debug("第 \(i) 次尝试获取宿舍 \(dorm.buildingName)-\(dorm.room) 电量成功: \(fetchedElectricity!)")
                    break
                } catch {
                    Logger.electricityBackgroundTask.warning("第 \(i) 次获取电量失败: \(error.localizedDescription)")
                    if i < 3 { try await Task.sleep(for: .seconds(2)) }
                }
            }

            guard let newElectricity = fetchedElectricity else {
                Logger.electricityBackgroundTask.error("获取电量彻底失败: 多次尝试均未成功")
                return false
            }

            guard let dormID = dorm.id else {
                Logger.electricityBackgroundTask.error("宿舍记录缺少主键，无法更新电量")
                return false
            }

            try await pool.write { db in
                try DormGRDB.updateElectricity(dormID: dormID, electricity: newElectricity, in: db)
            }
            WidgetTimelineRefreshHelper.reloadDormElectricity()
            Logger.electricityBackgroundTask.debug("\(dorm.buildingName)-\(dorm.room) 电量写入数据库成功")

            let content = UNMutableNotificationContent()
            content.title = "宿舍电量查询"
            content.body = "\(dorm.buildingName) \(dorm.room) 当前电量: \(String(format: "%.2f", newElectricity)) 度"
            content.sound = .default
            content.badge = 0

            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
            do {
                try await UNUserNotificationCenter.current().add(request)
                Logger.electricityBackgroundTask.debug("当前电量推送调度成功")
            } catch {
                Logger.electricityBackgroundTask.error("推送调度失败: \(error.localizedDescription)")
            }

            return true

        } catch {
            if error is CancellationError {
                Logger.electricityBackgroundTask.debug("后台任务因超时被取消")
                return false
            }
            Logger.electricityBackgroundTask.error("后台任务执行发生意外错误: \(error.localizedDescription)")
            return false
        }
    }
}

extension Logger {
    static let electricityBackgroundTask = Logger(appCategory: "ElectricityBackgroundTask")
}

#endif
