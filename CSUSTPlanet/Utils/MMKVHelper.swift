//
//  MMKVHelper.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2025/10/1.
//

import Foundation
import MMKV

class MMKVHelper {
    static let shared = MMKVHelper()

    private init() {}

    private(set) var defaultMMKV: MMKV!

    func setupMMKV() {
        guard let mmkvDirectoryURL = Constants.mmkvDirectoryURL else {
            fatalError("Failed to get MMKV directory URL")
        }
        MMKV.initialize(rootDir: mmkvDirectoryURL.path)
        guard let defaultMMKV = MMKV(mmapID: Constants.mmkvID) else {
            fatalError("Failed to initialize MMKV with ID: \(Constants.mmkvID)")
        }
        self.defaultMMKV = defaultMMKV
    }
}
