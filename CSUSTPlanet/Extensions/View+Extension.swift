//
//  View+Extension.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2025/12/31.
//

import SwiftUI

// MARK: - View Modifier

struct TrackPageModifier: ViewModifier {
    @Environment(\.trackPath) var parentPath
    let segment: String

    var fullPath: [String] {
        parentPath + [segment]
    }

    func body(content: Content) -> some View {
        content
            .environment(\.trackPath, fullPath)
            .onAppear {
                TrackHelper.shared.views(path: fullPath)
            }
    }
}

// MARK: - View Extension

extension View {
    func trackView(_ segment: String) -> some View {
        self.modifier(TrackPageModifier(segment: segment))
    }

    func trackRoot(_ name: String) -> some View {
        self.environment(\.trackPath, [name])
    }
}
