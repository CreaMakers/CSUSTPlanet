//
//  SharedModelUtil.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/21.
//

import Foundation
import OSLog
import SwiftData

enum SharedModelUtil {
    static let schema = Schema([
        Dorm.self,
        ElectricityRecord.self,
    ])

    static let container: ModelContainer = {
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(Constants.appGroupID),
            cloudKitDatabase: .private(Constants.iCloudID)
        )

        Logger.sharedModel.info("正在使用 iCloud 容器：\(String(describing: config.cloudKitDatabase))")

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            Logger.sharedModel.error("ModelContainer 初始化失败: \(error)")
            fatalError("ModelContainer 初始化失败: \(error)")
        }
    }()

    @MainActor
    static let mainContext: ModelContext = container.mainContext

    static var context: ModelContext { return ModelContext(container) }

    @MainActor
    static func clearAllData() throws {
        let context = self.context
        try context.delete(model: Dorm.self)
        try context.delete(model: ElectricityRecord.self)
        try context.save()
    }
}
