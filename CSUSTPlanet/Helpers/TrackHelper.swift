//
//  TrackHelper.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/30.
//

import MatomoTracker

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
    }

    func views(_ names: [String]) {
        tracker.track(view: names)
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
    }

    func flush() {
        tracker.dispatch()
    }

    func updateUserID(_ id: String?) {
        tracker.userId = id
    }
}
