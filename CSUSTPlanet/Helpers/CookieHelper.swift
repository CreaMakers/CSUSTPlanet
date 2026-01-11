//
//  CookieHelper.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/16.
//

import Alamofire
import CSUSTKit
import Foundation

final class CookieHelper {
    static let shared = CookieHelper()

    let session: Session

    private init() {
        let configuration = URLSessionConfiguration.default
        if let data = KeychainHelper.shared.cookies {
            if let cookies = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, HTTPCookie.self], from: data) as? [HTTPCookie] {
                for cookie in cookies {
                    configuration.httpCookieStorage?.setCookie(cookie)
                }
            }
        }
        self.session = Session(
            configuration: configuration,
            interceptor: EduHelper.EduRequestInterceptor(maxRetryCount: 5)
        )
    }

    func clearCookies() {
        if let storage = session.sessionConfiguration.httpCookieStorage {
            if let cookies = storage.cookies {
                for cookie in cookies {
                    storage.deleteCookie(cookie)
                }
            }
        }
        KeychainHelper.shared.cookies = nil
    }

    func updateCookies(_ cookies: [HTTPCookie]) {
        guard let storage = session.sessionConfiguration.httpCookieStorage else { return }
        cookies.forEach { storage.setCookie($0) }
    }

    func save() {
        guard let cookies = session.sessionConfiguration.httpCookieStorage?.cookies else { return }
        let data = try? NSKeyedArchiver.archivedData(withRootObject: cookies, requiringSecureCoding: true)
        KeychainHelper.shared.cookies = data
    }
}
