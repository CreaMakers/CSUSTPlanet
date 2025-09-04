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
        GradeAnalysis.self,
        CourseSchedule.self,
        GradeQuery.self,
        ExamSchedule.self,
        UrgentCourse.self,
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
}
