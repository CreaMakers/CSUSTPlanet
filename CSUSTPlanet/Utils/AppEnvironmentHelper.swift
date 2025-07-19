//
//  AppEnvironmentHelper.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/19.
//

import Foundation

enum AppEnvironment {
    case debug
    case testFlight
    case appStore
}

class AppEnvironmentHelper {
    static func isTestFlight() -> Bool {
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL else {
            return false
        }
        return appStoreReceiptURL.lastPathComponent == "sandboxReceipt"
    }

    static func currentEnvironment() -> AppEnvironment {
#if DEBUG
        return .debug
#else
        if isTestFlight() {
            return .testFlight
        } else {
            return .appStore
        }
#endif
    }
}
