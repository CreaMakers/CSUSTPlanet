//
//  KeychainHelper.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import Foundation

final class KeychainHelper {
    static let shared = KeychainHelper()

    private init() {}

    // MARK: - Core Methods

    func set(_ data: Data?, forKey key: String) {
        guard let data = data else {
            delete(forKey: key)
            return
        }
        let query = baseQuery(key: key)
        SecItemDelete(query as CFDictionary)
        var newQuery = query
        newQuery[kSecValueData as String] = data
        newQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(newQuery as CFDictionary, nil)
    }

    func getData(forKey key: String) -> Data? {
        var query = baseQuery(key: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        return status == errSecSuccess ? (dataTypeRef as? Data) : nil
    }

    // MARK: - Convenience Methods

    func set(_ string: String?, forKey key: String) {
        guard let string = string else {
            delete(forKey: key)
            return
        }
        set(string.data(using: .utf8), forKey: key)
    }

    func getString(forKey key: String) -> String? {
        guard let data = getData(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Helper

    func delete(forKey key: String) {
        let query = baseQuery(key: key)
        SecItemDelete(query as CFDictionary)
    }

    func deleteAll() {
        let secClasses: [CFTypeRef] = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity,
        ]
        for secClass in secClasses {
            let query: [String: Any] = [
                kSecClass as String: secClass,
                kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
                kSecAttrAccessGroup as String: Constants.keychainGroup,
            ]
            SecItemDelete(query as CFDictionary)
        }
    }

    private func baseQuery(key: String) -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: Constants.keychainGroup
        ]
    }
}

// MARK: - Business Properties

extension KeychainHelper {
    var physicsExperimentUsername: String? {
        get { getString(forKey: "PhysicsExperimentUsername") }
        set { set(newValue, forKey: "PhysicsExperimentUsername") }
    }

    var physicsExperimentPassword: String? {
        get { getString(forKey: "PhysicsExperimentPassword") }
        set { set(newValue, forKey: "PhysicsExperimentPassword") }
    }

    var ssoUsername: String? {
        get { getString(forKey: "SSOUsername") }
        set { set(newValue, forKey: "SSOUsername") }
    }

    var ssoPassword: String? {
        get { getString(forKey: "SSOPassword") }
        set { set(newValue, forKey: "SSOPassword") }
    }

    var ssoCookies: Data? {
        get { getData(forKey: "SSOCookies") }
        set { set(newValue, forKey: "SSOCookies") }
    }

    var cookies: Data? {
        get { getData(forKey: "Cookies") }
        set { set(newValue, forKey: "Cookies") }
    }
}