//
//  GlobalManager.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import Foundation
import OSLog
import SwiftUI

#if os(macOS)
import AppKit
#endif

@Observable
@MainActor
final class GlobalManager {
    static let shared = GlobalManager()

    @ObservationIgnored private var isCheckingAppVersion = false

    private init() {
        appearance = MMKVHelper.GlobalManager.appearance
        isUserAgreementAccepted = MMKVHelper.GlobalManager.isUserAgreementAccepted
        isWebVPNModeEnabled = MMKVHelper.GlobalManager.isWebVPNModeEnabled
        isOnboardingPresented = !MMKVHelper.GlobalManager.hasCompletedOnboarding

        #if os(macOS)
        applyMacOSAppearance(appearance)
        #endif

        TrackHelper.shared.updateIsOptedOut(!isUserAgreementAccepted)

        Task { await checkAppVersion() }
    }

    var appearance: String {
        didSet {
            MMKVHelper.GlobalManager.appearance = appearance
            #if os(macOS)
            applyMacOSAppearance(appearance)
            #endif
        }
    }
    var preferredColorScheme: ColorScheme? {
        switch appearance {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
    var isUserAgreementAccepted: Bool {
        didSet {
            MMKVHelper.GlobalManager.isUserAgreementAccepted = isUserAgreementAccepted
            TrackHelper.shared.updateIsOptedOut(!isUserAgreementAccepted)
        }
    }
    var isUserAgreementShowing: Binding<Bool> {
        Binding(get: { !self.isUserAgreementAccepted }, set: { self.isUserAgreementAccepted = !$0 })
    }
    var isOnboardingSheetShowing: Binding<Bool> {
        Binding(
            get: { self.isOnboardingPresented && !self.hasDatabaseFatalError && self.isUserAgreementAccepted && !self.isAppUpdateSheetPresented },
            set: { self.isOnboardingPresented = $0 }
        )
    }
    var isWebVPNModeEnabled: Bool {
        didSet {
            MMKVHelper.GlobalManager.isWebVPNModeEnabled = isWebVPNModeEnabled
        }
    }
    var isOnboardingPresented: Bool

    var hasDatabaseFatalError = DatabaseManager.shared.hasFatalError
    var databaseFatalErrorMessage: String = DatabaseManager.shared.fatalErrorMessage

    var latestAppVersion: PlanetConfigService.AppVersion?
    var isAppUpdateSheetPresented: Bool = false
    var isForceUpdateRequired: Bool = false

    var unreadAnnouncementsCount: Int = 0

    private func checkAppVersion() async {
        guard !isCheckingAppVersion else { return }
        isCheckingAppVersion = true
        defer { isCheckingAppVersion = false }

        guard let currentVersionName = AppVersionUtil.currentVersionName, let currentVersionCode = AppVersionUtil.currentVersionCode else {
            Logger.globalManager.error("启动版本检查失败：无法解析当前版本号")
            return
        }

        do {
            let result = try await PlanetConfigService.checkAppVersion(currentVersionCode: currentVersionCode)

            guard result.hasUpdate else {
                Logger.globalManager.debug("启动版本检查完成：当前已是最新版本 \(currentVersionName, privacy: .public) (\(currentVersionCode))")
                return
            }

            guard let latestVersion = result.latestVersion else {
                Logger.globalManager.error("启动版本检查结果异常：hasUpdate 为 true 但 latestVersion 为空")
                return
            }

            if !result.isForceUpdate, MMKVHelper.GlobalManager.ignoredAppUpdateVersionCode == latestVersion.versionCode {
                Logger.globalManager.info("启动版本检查发现已忽略的版本更新：\(latestVersion.versionName, privacy: .public) (\(latestVersion.versionCode))，本次不再提示")
                return
            }

            self.latestAppVersion = latestVersion
            isForceUpdateRequired = result.isForceUpdate
            isAppUpdateSheetPresented = true

            Logger.globalManager.info("启动版本检查发现新版本：当前 \(currentVersionName, privacy: .public) (\(currentVersionCode))，最新 \(latestVersion.versionName, privacy: .public) (\(latestVersion.versionCode))，强制更新：\(result.isForceUpdate)")
        } catch {
            Logger.globalManager.error("启动版本检查失败：\(error.localizedDescription, privacy: .public)")
        }
    }

    func dismissAppUpdateSheet() {
        guard !isForceUpdateRequired else { return }
        isAppUpdateSheetPresented = false
    }

    func completeOnboarding() {
        MMKVHelper.GlobalManager.hasCompletedOnboarding = true
        isOnboardingPresented = false
    }

    #if os(macOS)
    private func applyMacOSAppearance(_ appearanceName: String) {
        switch appearanceName {
        case "light":
            PlatformApplication.shared.appearance = NSAppearance(named: .aqua)
        case "dark":
            PlatformApplication.shared.appearance = NSAppearance(named: .darkAqua)
        default:
            PlatformApplication.shared.appearance = nil
        }
    }
    #endif

    func ignoreCurrentAppUpdate() {
        guard !isForceUpdateRequired, let latestAppVersion else { return }
        MMKVHelper.GlobalManager.ignoredAppUpdateVersionCode = latestAppVersion.versionCode
        Logger.globalManager.info("用户已忽略版本更新：\(latestAppVersion.versionName, privacy: .public) (\(latestAppVersion.versionCode))")
        dismissAppUpdateSheet()
    }
}

extension Logger {
    static let globalManager = Logger(appCategory: "GlobalManager")
}
