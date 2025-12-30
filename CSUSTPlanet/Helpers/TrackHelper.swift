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
}
