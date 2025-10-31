//
//  ElectricityBindingDTO.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/31.
//

import Foundation

struct ElectricityBindingDTO: Codable {
    let id: String?
    let studentId: String
    let deviceToken: String
    let isDebug: Bool
    let campus: String
    let building: String
    let room: String
    let scheduleHour: Int
    let scheduleMinute: Int
}
