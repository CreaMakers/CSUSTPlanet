//
//  PhysicsExperimentManager.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/11/4.
//

import CSUSTKit
import Foundation

enum PhysicsExperimentManagerError: Error, LocalizedError {
    case notLoggedIn

    var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return "未登录大物实验"
        }
    }
}

@MainActor
class PhysicsExperimentManager: ObservableObject {
    static let shared = PhysicsExperimentManager()

    private init() {}

    private var physicsExperimentHelper: PhysicsExperimentHelper?

    @Published var isLoggingIn: Bool = false

    func login(username: String, password: String) async throws {
        isLoggingIn = true
        defer {
            isLoggingIn = false
        }

        if physicsExperimentHelper == nil {
            if MMKVManager.shared.isWebVPNModeEnabled && AuthManager.shared.isLoggedIn {
                physicsExperimentHelper = PhysicsExperimentHelper(mode: .webVpn, session: AuthManager.shared.ssoHelper.getSession())
            } else {
                physicsExperimentHelper = PhysicsExperimentHelper()
            }
        }

        try await physicsExperimentHelper?.login(username: username, password: password)
        KeychainHelper.shared.physicsExperimentUsername = username
        KeychainHelper.shared.physicsExperimentPassword = password
    }

    func getCourseGrades() async throws -> [PhysicsExperimentHelper.CourseGrade] {
        guard let physicsExperimentHelper = physicsExperimentHelper else {
            throw PhysicsExperimentManagerError.notLoggedIn
        }
        return try await physicsExperimentHelper.getCourseGrades()
    }

    func getCourses() async throws -> [PhysicsExperimentHelper.Course] {
        guard let physicsExperimentHelper = physicsExperimentHelper else {
            throw PhysicsExperimentManagerError.notLoggedIn
        }
        return try await physicsExperimentHelper.getCourses()
    }
}
