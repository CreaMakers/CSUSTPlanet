//
//  AssetUtil.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/20.
//

import Foundation

enum AssetUtil {
    static func loadMarkdownFile(named filename: String) -> String? {
        guard let fileURL = Bundle.main.url(forResource: filename, withExtension: "md") else {
            return nil
        }
        return try? String(contentsOf: fileURL, encoding: .utf8)
    }

    static func bundleInfo(forKey key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            fatalError("Missing or invalid Info.plist key: \(key)")
        }
        return value
    }
}
