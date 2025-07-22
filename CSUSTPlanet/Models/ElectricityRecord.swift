//
//  ElectricityRecord.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import Foundation
import SwiftData

@Model
class ElectricityRecord {
    var electricity: Double = 0
    var date: Date = Date()

    var dorm: Dorm?

    init(electricity: Double, date: Date, dorm: Dorm? = nil) {
        self.electricity = electricity
        self.date = date
        self.dorm = dorm
    }
}
