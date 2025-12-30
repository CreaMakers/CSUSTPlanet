//
//  Constants.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2025/10/1.
//

import Foundation

enum Constants {
    static let appGroupID = AssetUtil.bundleInfo(forKey: "ConfigAppGroupID")
    static let iCloudID = AssetUtil.bundleInfo(forKey: "ConfigCloudContainerID")
    static let keychainGroup = AssetUtil.bundleInfo(forKey: "ConfigKeychainGroup")
    static let appBundleID = AssetUtil.bundleInfo(forKey: "ConfigAppBundleID")
    static let widgetBundleID = AssetUtil.bundleInfo(forKey: "ConfigWidgetBundleID")
    static let matomoURL = AssetUtil.bundleInfo(forKey: "ConfigMatomoURL")
    static let matomoSiteID = AssetUtil.bundleInfo(forKey: "ConfigMatomoSiteID")

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
        switch AppEnvironmentUtil.environment {
        case .debug: return "debug"
        case .testFlight: return "testFlight"
        case .appStore: return "appStore"
        }
    }

    private static let apiHostProd = AssetUtil.bundleInfo(forKey: "ConfigApiHostProd")
    private static let apiHostDev = AssetUtil.bundleInfo(forKey: "ConfigApiHostDev")

    static var backendHost: String {
        switch AppEnvironmentUtil.environment {
        case .appStore, .testFlight:
            return apiHostProd
        case .debug:
            return apiHostDev
        }
    }
}
