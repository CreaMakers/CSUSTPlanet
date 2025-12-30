//
//  View+Extension.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2025/12/30.
//

import SwiftUI

struct TrackPageModifier: ViewModifier {
    let path: [String]

    func body(content: Content) -> some View {
        content
            .onAppear {
                TrackHelper.shared.views(path: path)
            }
    }
}

extension View {
    func track(_ path: [String]) -> some View {
        self.modifier(TrackPageModifier(path: path))
    }
}
