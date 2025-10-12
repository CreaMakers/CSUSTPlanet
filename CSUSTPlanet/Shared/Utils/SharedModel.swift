//
//  SharedModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/21.
//

import Foundation
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
                groupContainer: .identifier("group.com.zhelearn.CSUSTPlanet"),
            )
            debugPrint("Using shared group container for widget: \(config.groupContainer)")
        #else
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier("group.com.zhelearn.CSUSTPlanet"),
                cloudKitDatabase: .private("iCloud.com.zhelearn.CSUSTPlanet"),
            )
            debugPrint("Using iCloud container for app: \(config.cloudKitDatabase)")
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
