//
//  View+Toolbar.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/3.
//

import Foundation
import SwiftUI

private struct HideTabBarOnCompactModifier: ViewModifier {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    @ViewBuilder
    func body(content: Content) -> some View {
        #if os(iOS)
        if sizeClass == .compact {
            content.toolbar(.hidden, for: .tabBar)
        } else {
            content
        }
        #else
        content
        #endif
    }
}

extension View {
    @ViewBuilder
    func inlineToolbarTitle() -> some View {
        #if os(iOS)
        self.toolbarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func largeToolbarTitle() -> some View {
        #if os(iOS)
        self.toolbarTitleDisplayMode(.large)
        #else
        self
        #endif
    }

    func hideTabBarOnCompact() -> some View {
        modifier(HideTabBarOnCompactModifier())
    }
}
