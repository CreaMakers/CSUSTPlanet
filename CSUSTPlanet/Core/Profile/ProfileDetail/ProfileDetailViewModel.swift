//
//  ProfileViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/10.
//

import CSUSTKit
import Foundation

@MainActor
@Observable
class ProfileDetailViewModel {
    var ssoProfile: SSOHelper.Profile?
    var isLoadingSSOProfile: Bool = false

    var eduProfile: EduHelper.Profile?
    var isLoadingEduProfile: Bool = false

    var moocProfile: MoocHelper.Profile?
    var isLoadingMoocProfile: Bool = false

    var errorToast: ToastState = .errorTitle

    @ObservationIgnored var isInitial = true

    func loadInitial() async {
        guard isInitial else { return }
        isInitial = false
        await loadAll()
    }

    func loadAll() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadSSOProfile() }
            group.addTask { await self.loadEduProfile() }
            group.addTask { await self.loadMoocProfile() }
        }
    }

    func loadSSOProfile() async {
        guard !isLoadingSSOProfile else { return }
        isLoadingSSOProfile = true
        defer { isLoadingSSOProfile = false }

        do {
            ssoProfile = try await AuthManager.shared.withAuthRetry(system: .sso) {
                try await AuthManager.shared.ssoHelper.getLoginUser()
            }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func loadEduProfile() async {
        guard !isLoadingEduProfile else { return }
        isLoadingEduProfile = true
        defer { isLoadingEduProfile = false }

        do {
            eduProfile = try await AuthManager.shared.withAuthRetry(system: .edu) {
                try await AuthManager.shared.eduHelper.profileService.getProfile()
            }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func loadMoocProfile() async {
        guard !isLoadingMoocProfile else { return }
        isLoadingMoocProfile = true
        defer { isLoadingMoocProfile = false }

        do {
            moocProfile = try await AuthManager.shared.withAuthRetry(system: .mooc) {
                try await AuthManager.shared.moocHelper.getProfile()
            }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}
