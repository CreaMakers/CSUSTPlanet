//
//  AuthManager+RetryProtocol.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/5/28.
//

enum CampusSystem {
    case sso
    case edu
    case mooc
    case campusCard
}

protocol AuthRetryProvider {
    func withAuthRetry<T>(
        system: CampusSystem,
        maxRetries: Int,
        operation: @MainActor @escaping () async throws -> T
    ) async throws -> T
}
