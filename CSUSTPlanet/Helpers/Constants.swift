//
//  Constants.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2025/10/1.
//

import Foundation

enum Constants {
    static let appGroupID = AssetHelper.bundleInfo(forKey: "ConfigAppGroupID")
    static let iCloudID = AssetHelper.bundleInfo(forKey: "ConfigCloudContainerID")
    static let keychainGroup = AssetHelper.bundleInfo(forKey: "ConfigKeychainGroup")
    static let appBundleID = AssetHelper.bundleInfo(forKey: "ConfigAppBundleID")
    static let widgetBundleID = AssetHelper.bundleInfo(forKey: "ConfigWidgetBundleID")

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

    private static let apiHostProd = AssetHelper.bundleInfo(forKey: "ConfigApiHostProd")
    private static let apiHostDev = AssetHelper.bundleInfo(forKey: "ConfigApiHostDev")
    private static let apiHostLocal = AssetHelper.bundleInfo(forKey: "ConfigApiHostLocal")

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
