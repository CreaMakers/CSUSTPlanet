//
//  Constants.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2025/10/1.
//

import Foundation

class Constants {
    static let appGroupID = AssetUtils.bundleInfo(forKey: "ConfigAppGroupID")
    static let iCloudID = AssetUtils.bundleInfo(forKey: "ConfigCloudContainerID")
    static let keychainGroup = AssetUtils.bundleInfo(forKey: "ConfigKeychainGroup")
    static let appBundleID = AssetUtils.bundleInfo(forKey: "ConfigAppBundleID")
    static let widgetBundleID = AssetUtils.bundleInfo(forKey: "ConfigWidgetBundleID")

    static let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)

    static let mmkvDirectoryURL: URL? = {
        guard let sharedURL = sharedContainerURL else { return nil }
        let mmkvDir = sharedURL.appendingPathComponent("mmkv")
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: mmkvDir.path) {
            try? fileManager.createDirectory(at: mmkvDir, withIntermediateDirectories: true)
        }
        return mmkvDir
    }()
    static var mmkvID: String {
        switch AppEnvironmentHelper.environment {
        case .debug: return "debug"
        case .testFlight: return "testFlight"
        case .appStore: return "appStore"
        }
    }

    private static let apiHostProd = AssetUtils.bundleInfo(forKey: "ConfigApiHostProd")
    private static let apiHostDev = AssetUtils.bundleInfo(forKey: "ConfigApiHostDev")
    private static let apiHostLocal = AssetUtils.bundleInfo(forKey: "ConfigApiHostLocal")

    static var backendHost: String {
        switch AppEnvironmentHelper.environment {
        case .appStore, .testFlight:
            return apiHostProd
        case .debug:
            #if targetEnvironment(simulator)
                return apiHostLocal
            #else
                return apiHostDev
            #endif
        }
    }
}
