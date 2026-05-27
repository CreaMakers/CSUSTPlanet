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
        guard let selectedDormEntity = dorm,
            let dormID = selectedDormEntity.dormID,
            let pool = try? DatabaseManager.shared.poolThrows,
            let localDorm = try? await pool.read({ db in try DormGRDB.filter(key: dormID).fetchOne(db) }),
            let campus = CampusCardHelper.Campus(rawValue: localDorm.campusName)
        else {
            return
        }

        // 解析校区与楼栋信息
        let building = CampusCardHelper.Building(name: localDorm.buildingName, id: localDorm.buildingID, campus: campus)
        // TODO: Need to fix
        let room = CampusCardHelper.Room(name: localDorm.room, id: "", building: building)

        // 拉取网络数据并更新数据库
        guard let networkElectricity = try? await CampusCardHelper().getElectricity(room: room) else {
            return
        }
        try? await pool.write { db in
            try DormGRDB.updateElectricity(dormID: dormID, electricity: networkElectricity, in: db)
        }

        GRDBIPCNotifier.shared.notifyChange()

        return
    }
}
