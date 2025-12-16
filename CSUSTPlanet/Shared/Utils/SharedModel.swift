//
//  SharedModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/21.
//

import Foundation
import OSLog
import SwiftData

class SharedModel {
    static let schema = Schema([
        Dorm.self,
        ElectricityRecord.self,
    ])

    static let container: ModelContainer = {
        #if WIDGET
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier(Constants.appGroupID),
            )
            Logger.sharedModel.info("小组件正在使用共享组容器：\(String(describing: config.groupContainer))")
        #else
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier(Constants.appGroupID),
                cloudKitDatabase: .private(Constants.iCloudID),
            )
            Logger.sharedModel.info("App 正在使用 iCloud 容器：\(String(describing: config.cloudKitDatabase))")
        #endif

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    @MainActor
    static let mainContext: ModelContext = container.mainContext

    static var context: ModelContext {
        return ModelContext(container)
    }

    @MainActor
    static func clearAllData() throws {
        let context = self.context
        try context.delete(model: Dorm.self)
        try context.delete(model: ElectricityRecord.self)
        try context.save()
    }
}
