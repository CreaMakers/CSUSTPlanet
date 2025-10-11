//
//  RealmManager.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/11.
//

import Foundation
import RealmSwift

class RealmManager {
    static let shared = RealmManager()

    private init() {}

    private var isInitialized: Bool = false

    func setup() {
        guard !isInitialized else { return }
        guard let realmDirectoryURL = Constants.realmDirectoryURL else {
            fatalError("Failed to get Realm directory URL")
        }
        let realmURL = realmDirectoryURL.appendingPathComponent("\(AppEnvironmentHelper.environment.rawValue).realm")
        var config = Realm.Configuration()
        config.fileURL = realmURL
        Realm.Configuration.defaultConfiguration = config
        isInitialized = true
    }
}
