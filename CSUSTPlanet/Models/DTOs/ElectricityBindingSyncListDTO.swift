//
//  ElectricityBindingSyncListDTO.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/31.
//

import Foundation

struct ElectricityBindingSyncListDTO: Codable {
    var studentId: String
    var deviceToken: String

    var bindings: [ElectricityBindingSyncDTO]
}
