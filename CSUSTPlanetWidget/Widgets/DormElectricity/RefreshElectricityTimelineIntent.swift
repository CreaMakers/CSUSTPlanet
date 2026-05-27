//
//  RefreshElectricityIntent.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/21.
//

import AppIntents
import CSUSTKit
import OSLog
import WidgetKit

struct RefreshElectricityTimelineIntent: AppIntent {
    static var title: LocalizedStringResource = "刷新宿舍电量"
    static var isDiscoverable: Bool = false

    @Parameter(title: "宿舍")
    var dorm: DormIntentEntity?

    init() {}

    init(dorm: DormIntentEntity) {
        self.dorm = dorm
    }

    func perform() async throws -> some IntentResult {
        TrackHelper.shared.event(category: "Widget", action: "Refresh", name: "DormElectricityWidget")
        await Self.update(dorm: dorm)
        return .result()
    }

    static func update(dorm: DormIntentEntity?) async {
        do {
            guard let selectedDormEntity = dorm,
                let dormID = selectedDormEntity.dormID,
                let pool = DatabaseManager.shared.pool,
                let localDorm = try await pool.read({ db in try DormGRDB.filter(key: dormID).fetchOne(db) })
            else {
                return
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
                        return
                    }
                    let loginForm = try await ssoHelper.getLoginForm()
                    try await ssoHelper.login(loginForm: loginForm, username: username, password: password, captcha: nil)

                    let (_, ticket) = try await ssoHelper.loginToCampusCard()
                    try await campusCardHelper.syncToken(ticket: ticket)

                    CookieHelper.shared.save()
                    KeychainUtil.campusCardToken = campusCardHelper.token
                }
            }

            // 拉取网络数据并更新数据库
            let electricity = try await ElectricityUtil.getElectricity(campusCardHelper, campusName: localDorm.campusName, buildingName: localDorm.buildingName, roomName: localDorm.room)
            try await pool.write { db in
                try DormGRDB.updateElectricity(dormID: dormID, electricity: electricity, in: db)
            }

            GRDBIPCNotifier.shared.notifyChange()
        } catch {
            return
        }
    }
}
