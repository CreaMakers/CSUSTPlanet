//
//  PhysicsExperimentLoginViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/11/4.
//

import Foundation
import SwiftUI

@MainActor
class PhysicsExperimentLoginViewModel: ObservableObject {
    @Published var username: String = KeychainHelper.shared.physicsExperimentUsername ?? ""
    @Published var password: String = KeychainHelper.shared.physicsExperimentPassword ?? ""
    @Published var isPasswordVisible: Bool = false
    @Published var isShowingError: Bool = false
    @Published var errorMessage: String = ""

    var isLoginDisabled: Bool {
        username.isEmpty || password.isEmpty || PhysicsExperimentManager.shared.isLoggingIn
    }

    func login(_ isPresented: Binding<Bool>) {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "请输入用户名和密码"
            isShowingError = true
            return
        }

        Task {
            do {
                try await PhysicsExperimentManager.shared.login(username: username, password: password)
                isPresented.wrappedValue = false
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }
}
