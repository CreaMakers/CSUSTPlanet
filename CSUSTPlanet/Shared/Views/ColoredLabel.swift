//
//  ColoredLabel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/19.
//

import SwiftUI

struct ColoredLabel: View {
    let title: String
    let iconName: String
    let color: Color

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: iconName)
                .foregroundColor(color)
        }
    }
}
