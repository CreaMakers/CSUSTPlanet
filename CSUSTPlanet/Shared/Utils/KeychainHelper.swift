//
//  KeychainHelper.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import Foundation

enum KeychainHelper {
    static func teamID() -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "bundleSeedID",
            kSecAttrService as String: "",
            kSecReturnAttributes as String: kCFBooleanTrue as Any,
        ]

        var result: CFTypeRef?
        var status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            status = SecItemAdd(query as CFDictionary, &result)
        }

        guard status == errSecSuccess else {
            fatalError("Failed to retrieve team ID from Keychain: \(status)")
        }

        guard let accessGroup = (result as? NSDictionary)?.object(forKey: kSecAttrAccessGroup) as? String else {
            fatalError("Failed to parse access group from Keychain result")
        }

        return accessGroup.components(separatedBy: ".").first!
    }

    static var accessGroup: String {
        "\(teamID()).com.zhelearn.CSUSTPlanet"
    }

    static func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessGroup as String: accessGroup,
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccessGroup as String: accessGroup,
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    static func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: accessGroup,
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }

    static func deleteAll() {
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
                kSecAttrAccessGroup as String: accessGroup,
            ]
            SecItemDelete(query as CFDictionary)
        }
    }
}
