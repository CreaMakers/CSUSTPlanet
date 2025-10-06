//
//  AssetUtils.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/20.
//

import Foundation

class AssetUtils {
    static func loadMarkdownFile(named filename: String) -> String? {
        guard let fileURL = Bundle.main.url(forResource: filename, withExtension: "md") else {
            return nil
        }
        return try? String(contentsOf: fileURL, encoding: .utf8)
    }
}
