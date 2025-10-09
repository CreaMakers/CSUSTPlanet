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

        return try! ModelContainer(for: schema, configurations: [config])
    }()

    static var context: ModelContext {
        ModelContext(container)
    }

    static func clearAllData() throws {
        let context = Self.context

        let dormFetch = FetchDescriptor<Dorm>()
        let dorms = try context.fetch(dormFetch)
        for dorm in dorms {
            context.delete(dorm)
        }

        let electricityFetch = FetchDescriptor<ElectricityRecord>()
        let electricityRecords = try context.fetch(electricityFetch)
        for record in electricityRecords {
            context.delete(record)
        }

        try context.save()
    }
}
