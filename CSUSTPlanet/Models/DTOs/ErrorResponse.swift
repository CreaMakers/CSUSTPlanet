//
//  ErrorResponse.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/31.
//

import Foundation

struct ErrorResponse: Decodable {
    let reason: String
    let error: Bool
}
