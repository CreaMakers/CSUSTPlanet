//
//  TrackHelper.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/30.
//

import CryptoKit
import MatomoTracker
import OSLog

final class TrackHelper {
    static let shared = TrackHelper()

    private(set) var tracker: MatomoTracker

    private init() {
        tracker = MatomoTracker(siteId: Constants.matomoSiteID, baseURL: URL(string: Constants.matomoURL)!)
    }

    func setup() {
        tracker.dispatchInterval = 60

        #if DEBUG
            tracker.logger = DefaultLogger(minLevel: .debug)
        #endif

        Logger.trackHelper.debug("初始化 MatomoTracker")
    }

    func views(path: [String]) {
        tracker.track(view: path)
        Logger.trackHelper.debug("跟踪页面: \(path.joined(separator: "/"))")
    }

    func event(category: String, action: String, name: String? = nil, value: NSNumber? = nil, path: [String]? = nil) {
        let virtualURL = path.flatMap { URL(string: "http://\(Constants.appBundleID.lowercased())/" + $0.joined(separator: "/")) }
        tracker.track(
            eventWithCategory: category,
            action: action,
            name: name,
            number: value,
            url: virtualURL
        )
        Logger.trackHelper.debug("跟踪事件: \(category) - \(action) - \(name ?? "nil") - \(String(describing: value)) - \(String(describing: virtualURL))")
    }

    func flush() {
        tracker.dispatch()
        Logger.trackHelper.debug("刷新 MatomoTracker")
    }

    func updateUserID(_ id: String?) {
        guard let rawID = id, !rawID.isEmpty else {
            tracker.userId = nil
            return
        }

        let inputData = Data((rawID + Constants.matomoUserIDSalt).utf8)
        let hashed = SHA256.hash(data: inputData)
        let finalID = hashed.compactMap { String(format: "%02x", $0) }.joined()

        tracker.userId = finalID
        Logger.trackHelper.debug("用户ID已脱敏并更新")
    }
}
