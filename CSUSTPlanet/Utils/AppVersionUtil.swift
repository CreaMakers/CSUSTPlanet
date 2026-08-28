//
//  AppVersionUtil.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/29.
//

import Foundation

enum AppVersionUtil {
    static var currentVersionName: String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    static var currentVersionCode: Int? {
        guard let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else { return nil }
        return Int(buildNumber)
    }
}
