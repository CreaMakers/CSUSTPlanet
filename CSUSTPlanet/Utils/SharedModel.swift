//
//  SharedModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/21.
//

import Foundation
import SwiftData

class SharedModel {
    static let container: ModelContainer = {
        let schema = Schema([Dorm.self, ElectricityRecord.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.zhelearn.CSUSTPlanet")
        )
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    static var context: ModelContext {
        ModelContext(container)
    }
}
