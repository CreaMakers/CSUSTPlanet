//
//  FilterToolbarLabel.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/9/9.
//

import SwiftUI

struct FilterToolbarLabel: View {
    let isActive: Bool

    var body: some View {
        Group {
            switch style {
            case .capsule(let scale):
                (isActive ? Color.white : Color.primary)
                    .scaleEffect(2)
                    .mask {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                    .background {
                        if isActive {
                            Capsule()
                                .foregroundStyle(Color.accentColor)
                                .scaledToFill()
                                .scaleEffect(scale)
                        }
                    }
            case .circle(let scale):
                Image(systemName: "line.3.horizontal.decrease")
                    .foregroundStyle(isActive ? Color.white : Color.accentColor)
                    .background {
                        if isActive {
                            Circle()
                                .foregroundStyle(Color.accentColor)
                                .scaleEffect(scale)
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }

    private var style: FilterToolbarLabelStyle {
        #if os(macOS)
        return .capsule(scale: 1.1)
        #elseif os(iOS)
        if #available(iOS 26.0, *) {
            return .capsule(scale: 1.65)
        }
        return .circle(scale: 1.65)
        #else
        return .circle(scale: 1.65)
        #endif
    }
}

private enum FilterToolbarLabelStyle {
    case capsule(scale: CGFloat)
    case circle(scale: CGFloat)
}
