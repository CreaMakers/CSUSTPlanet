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

    func setup() {
        guard let realmDirectoryURL = Constants.realmDirectoryURL else {
            fatalError("Failed to get Realm directory URL")
        }
        let realmURL = realmDirectoryURL.appendingPathComponent("\(Constants.mmkvID).realm")
        var config = Realm.Configuration()
        config.fileURL = realmURL
        Realm.Configuration.defaultConfiguration = config
    }
}
