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
        guard let version = currentVersionName else { return nil }
        return versionCode(from: version)
    }

    static func versionCode(from version: String) -> Int? {
        let rawComponents =
            version
            .split(separator: ".", omittingEmptySubsequences: false)
            .map(String.init)

        guard !rawComponents.isEmpty else { return nil }

        let normalizedComponents = Array(rawComponents.prefix(3))
        let paddedComponents = normalizedComponents + Array(repeating: "0", count: max(0, 3 - normalizedComponents.count))

        guard
            paddedComponents.count == 3,
            let major = Int(paddedComponents[0]),
            let minor = Int(paddedComponents[1]),
            let patch = Int(paddedComponents[2])
        else {
            return nil
        }

        return major * 1_000_000 + minor * 1_000 + patch
    }
}
