//
//  TrackHelper.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/30.
//

import Combine
import CryptoKit
import MatomoTracker
import OSLog

final class TrackHelper {
    static let shared = TrackHelper()

    private var trackerStorage: MatomoTracker?
    private var pendingIsOptedOut: Bool?
    private var pendingUserID: String? = MMKVHelper.Track.userId

    private var tracker: MatomoTracker {
        if let trackerStorage {
            return trackerStorage
        }

        let tracker = makeTracker()
        trackerStorage = tracker
        return tracker
    }

    private func makeTracker() -> MatomoTracker {
        let dispatcher = URLSessionDispatcher(baseURL: URL(string: Constants.matomoURL)!)
        let queue = MatomoGRDBQueue()
        let logger = MatomoLogger(minLevel: .debug)

        let instance = MatomoTracker(siteId: Constants.matomoSiteID, queue: queue, dispatcher: dispatcher)
        instance.logger = logger

        if let pendingIsOptedOut {
            instance.isOptedOut = pendingIsOptedOut
        }

        if let index = Int(Constants.matomoDimensionIDAppVersion),
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        {
            instance.setDimension("\(version) (\(buildNumber))", forIndex: index)
        }

        if let index = Int(Constants.matomoDimensionIDAppEnvironment) {
            instance.setDimension(EnvironmentUtil.environment.rawValue, forIndex: index)
        }

        #if WIDGET
        instance.dispatchInterval = 0
        #else
        instance.dispatchInterval = 10
        #endif

        Logger.trackHelper.debug("初始化 MatomoTracker 完成")

        if let pendingUserID {
            instance.userId = pendingUserID
            Logger.trackHelper.debug("初始化时同步用户ID: \(pendingUserID)")
        }
        return instance
    }

    func views(path: [String]) {
        tracker.track(view: path)
        Logger.trackHelper.debug("跟踪页面: \(path.joined(separator: "/"), privacy: .public)")
    }

    func event(category: String, action: String, name: String? = nil, value: Int? = nil) {
        let number: NSNumber? =
            if let value {
                NSNumber(value: value)
            } else {
                nil
            }

        tracker.track(
            eventWithCategory: category,
            action: action,
            name: name,
            number: number,
            url: nil
        )
        Logger.trackHelper.debug("跟踪事件: \(category, privacy: .public) - \(action, privacy: .public) - \(name ?? "nil", privacy: .public) - \(String(describing: value), privacy: .public)")
    }

    func flush() {
        tracker.dispatch()
        Logger.trackHelper.debug("刷新 MatomoTracker")
    }

    func updateUserID(_ id: String?) {
        guard let id = id, !id.isEmpty else {
            pendingUserID = nil
            trackerStorage?.userId = nil
            Logger.trackHelper.debug("用户ID已清空")
            return
        }
        pendingUserID = id
        trackerStorage?.userId = id
        Logger.trackHelper.debug("用户ID已更新: \(id)")
    }

    func updateIsOptedOut(_ isOptedOut: Bool) {
        pendingIsOptedOut = isOptedOut
        trackerStorage?.isOptedOut = isOptedOut
        Logger.trackHelper.debug("更新用户是否拒绝跟踪: \(isOptedOut, privacy: .public)")
    }
}

extension os.Logger {
    static let trackHelper = Logger(appCategory: "TrackHelper")
}

extension MMKVHelper {
    enum Track {
        @MMKVOptionalStorage(key: "GlobalVars.userId")
        static var userId: String?
    }
}
