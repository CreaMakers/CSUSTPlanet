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

    private func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessGroup as String: Constants.keychainGroup,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccessGroup as String: Constants.keychainGroup,
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess, let data = dataTypeRef as? Data { return String(data: data, encoding: .utf8) }
        return nil
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: Constants.keychainGroup,
        ]
        SecItemDelete(query as CFDictionary)
    }

    private func setValue(key: String, value: String?) {
        guard let value = value else {
            delete(key: key)
            return
        }
        save(key: key, value: value)
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
}

extension KeychainHelper {
    var physicsExperimentUsername: String? {
        get { retrieve(key: "PhysicsExperimentUsername") }
        set { setValue(key: "PhysicsExperimentUsername", value: newValue) }
    }

    var physicsExperimentPassword: String? {
        get { retrieve(key: "PhysicsExperimentPassword") }
        set { setValue(key: "PhysicsExperimentPassword", value: newValue) }
    }

    var ssoUsername: String? {
        get { retrieve(key: "SSOUsername") }
        set { setValue(key: "SSOUsername", value: newValue) }
    }

    var ssoPassword: String? {
        get { retrieve(key: "SSOPassword") }
        set { setValue(key: "SSOPassword", value: newValue) }
    }

    var ssoCookies: String? {
        get { retrieve(key: "SSOCookies") }
        set { setValue(key: "SSOCookies", value: newValue) }
    }
}
