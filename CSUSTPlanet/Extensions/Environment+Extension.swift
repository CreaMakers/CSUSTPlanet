//
//  Environment+Extension.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2025/12/31.
//

import SwiftUI

// MARK: - Environment Key

private struct TrackPathKey: EnvironmentKey {
    static let defaultValue: [String] = []
}

extension EnvironmentValues {
    var trackPath: [String] {
        get { self[TrackPathKey.self] }
        set { self[TrackPathKey.self] = newValue }
    }
}
