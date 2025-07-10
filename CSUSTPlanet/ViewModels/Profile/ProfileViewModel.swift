//
//  ProfileViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/10.
//

import CSUSTKit
import Foundation

@MainActor
class ProfileViewModel: ObservableObject {
    private var ssoHelper: SSOHelper?
    private var eduHelper: EduHelper?
    private var moocHelper: MoocHelper?

    @Published var ssoProfile: LoginUser?
    @Published var isSSOProfileLoading: Bool = false

    @Published var eduProfile: Profile?
    @Published var isEduProfileLoading: Bool = false

    @Published var moocProfile: MoocProfile?
    @Published var isMoocProfileLoading: Bool = false

    @Published var isShowingError: Bool = false
    @Published var errorMessage: String = ""

    init(ssoHelper: SSOHelper? = nil, eduHelper: EduHelper? = nil, moocHelper: MoocHelper? = nil, ssoProfile: LoginUser? = nil) {
        self.ssoHelper = ssoHelper
        self.eduHelper = eduHelper
        self.moocHelper = moocHelper

        self.ssoProfile = ssoProfile
    }

    func loadSSOProfile() {
        guard let ssoHelper = ssoHelper else {
            errorMessage = "SSOHelper未初始化"
            isShowingError = true
            return
        }

        isSSOProfileLoading = true
        Task {
            defer {
                isSSOProfileLoading = false
            }

            do {
                ssoProfile = try await ssoHelper.getLoginUser()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func loadEduProfile() {
        guard let eduHelper = eduHelper else {
            errorMessage = "EduHelper未初始化"
            isShowingError = true
            return
        }

        isEduProfileLoading = true
        Task {
            defer {
                isEduProfileLoading = false
            }

            do {
                eduProfile = try await eduHelper.profileService.getProfile()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func loadMoocProfile() {
        guard let moocHelper = moocHelper else {
            errorMessage = "MoocHelper未初始化"
            isShowingError = true
            return
        }

        isMoocProfileLoading = true
        Task {
            defer {
                isMoocProfileLoading = false
            }

            do {
                moocProfile = try await moocHelper.getProfile()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }
}
