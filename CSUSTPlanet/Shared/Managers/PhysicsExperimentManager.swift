//
//  PhysicsExperimentManager.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/11/4.
//

import CSUSTKit
import Foundation

class PhysicsExperimentManager: ObservableObject {
    static let shared = PhysicsExperimentManager()

    private init() {}

    var physicsExperimentHelper = PhysicsExperimentHelper()

    @Published var isLoggingIn: Bool = false

    func login(username: String, password: String) async throws {
        isLoggingIn = true
        defer {
            isLoggingIn = false
        }

        try await physicsExperimentHelper.login(username: username, password: password)
        KeychainHelper.save(key: "PhysicsExperimentUsername", value: username)
        KeychainHelper.save(key: "PhysicsExperimentPassword", value: password)
    }
}
