//
//  KeychainHelper.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import Foundation
import KeychainAccess
import Security

class KeychainHelper {
    static let shared = KeychainHelper()

    private init() {}

    private let keychain: Keychain = {
        return Keychain(service: Constants.appBundleID, accessGroup: Constants.keychainGroup)
            .accessibility(.afterFirstUnlock)
    }()

    private func setItem(_ value: String?, key: String) {
        guard let value = value else {
            try? keychain.remove(key)
            _ = deleteLegacy(key: key)
            return
        }
        try? keychain.set(value, key: key)
        _ = deleteLegacy(key: key)
    }

    private func getItem(key: String) -> String? {
        if let value = try? keychain.get(key) {
            return value
        }
        if let legacyValue = retrieveLegacy(key: key) {
            try? keychain.set(legacyValue, key: key)
            _ = deleteLegacy(key: key)
            return legacyValue
        }
        return nil
    }

    func deleteAll() {
        try? keychain.removeAll()
        deleteAllLegacy()
    }
}

// MARK: - Public Variables

extension KeychainHelper {
    /// SSO 用户名
    var ssoUsername: String? {
        get { getItem(key: "SSOUsername") }
        set { setItem(newValue, key: "SSOUsername") }
    }

    /// SSO 密码
    var ssoPassword: String? {
        get { getItem(key: "SSOPassword") }
        set { setItem(newValue, key: "SSOPassword") }
    }

    /// 物理实验用户名
    var physicsExperimentUsername: String? {
        get { getItem(key: "PhysicsExperimentUsername") }
        set { setItem(newValue, key: "PhysicsExperimentUsername") }
    }

    /// 物理实验密码
    var physicsExperimentPassword: String? {
        get { getItem(key: "PhysicsExperimentPassword") }
        set { setItem(newValue, key: "PhysicsExperimentPassword") }
    }

    /// SSO Cookies
    var ssoCookies: String? {
        get { getItem(key: "SSOCookies") }
        set { setItem(newValue, key: "SSOCookies") }
    }
}

// MARK: - Legacy Code
// 考虑版本1.6后删除

extension KeychainHelper {
    private func retrieveLegacy(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccessGroup as String: Constants.keychainGroup,
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    private func deleteLegacy(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: Constants.keychainGroup,
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }

    private func deleteAllLegacy() {
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
}
