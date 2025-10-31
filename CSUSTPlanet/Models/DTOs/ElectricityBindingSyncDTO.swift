//
//  ElectricityBindingSyncDTO.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/31.
//

import Foundation

struct ElectricityBindingSyncDTO: Codable {
    var campus: String
    var building: String
    var room: String
    var scheduleHour: Int
    var scheduleMinute: Int
}
