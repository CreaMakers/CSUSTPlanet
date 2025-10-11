//
//  Constants.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2025/10/1.
//

import Foundation

class Constants {
    private static let fileManager = FileManager.default

    static let appGroupID = "group.com.zhelearn.CSUSTPlanet"
    static let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    static let mmkvDirectoryURL: URL? = {
        guard let sharedURL = sharedContainerURL else { return nil }
        let mmkvDir = sharedURL.appendingPathComponent("mmkv")
        if !fileManager.fileExists(atPath: mmkvDir.path) {
            try? fileManager.createDirectory(at: mmkvDir, withIntermediateDirectories: true)
        }
        return mmkvDir
    }()
    static let realmDirectoryURL: URL? = {
        guard let sharedURL = sharedContainerURL else { return nil }
        let realmDir = sharedURL.appendingPathComponent("realm")
        if !fileManager.fileExists(atPath: realmDir.path) {
            try? fileManager.createDirectory(at: realmDir, withIntermediateDirectories: true)
        }
        return realmDir
    }()
    static var mmkvID: String {
        switch AppEnvironmentHelper.environment {
        case .debug: return "debug"
        case .testFlight: return "testFlight"
        case .appStore: return "appStore"
        }
    }
}
