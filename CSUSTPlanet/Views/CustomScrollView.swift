//
//  CustomScrollView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/6/15.
//

import SwiftUI

struct CustomScrollView<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        ScrollView {
            content()
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
        }
    }
}
