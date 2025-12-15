//
//  KeychainCookieStorage.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import Alamofire
import CSUSTKit
import Foundation

public class KeychainCookieStorage: CookieStorage {
    private let keychainKey = "SSOCookies"

    public init() {}

    public func saveCookies(for session: Session) {
        guard let cookies = session.sessionConfiguration.httpCookieStorage?.cookies else { return }

        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: cookies, requiringSecureCoding: false)
            let dataString = data.base64EncodedString()

            KeychainHelper.save(key: keychainKey, value: dataString)
        } catch {}
    }

    public func restoreCookies(to session: Session) {
        guard let dataString = KeychainHelper.retrieve(key: keychainKey),
            let data = Data(base64Encoded: dataString)
        else { return }

        do {
            if let cookies = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, HTTPCookie.self], from: data) as? [HTTPCookie] {
                for cookie in cookies {
                    session.sessionConfiguration.httpCookieStorage?.setCookie(cookie)
                }
            }
        } catch {}
    }

    public func clearCookies() {
        KeychainHelper.delete(key: keychainKey)
    }
}
