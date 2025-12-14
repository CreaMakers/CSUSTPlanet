//
//  Constants.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2025/10/1.
//

import Foundation

class Constants {
    static let appGroupID = Bundle.main.object(forInfoDictionaryKey: "ConfigAppGroupID") as! String
    static let iCloudID = Bundle.main.object(forInfoDictionaryKey: "ConfigCloudContainerID") as! String
    static let keychainGroup = Bundle.main.object(forInfoDictionaryKey: "ConfigKeychainGroup") as! String

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

    static var backendHost: String {
        switch AppEnvironmentHelper.environment {
        case .appStore, .testFlight:
            return "https://api.csustplanet.zhelearn.com"
        case .debug:
            #if targetEnvironment(simulator)
                return "http://localhost:8080"
            #else
                return "https://api-dev.csustplanet.zhelearn.com"
            #endif
        }
    }
}
