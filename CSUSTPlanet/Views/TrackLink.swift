//
//  TrackLink.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2025/12/31.
//

import Foundation
import SwiftUI

struct TrackLink<Destination: View, Label: View>: View {
    @Environment(\.trackPath) var currentPath

    let destination: Destination
    let label: Label

    init(destination: Destination, @ViewBuilder label: () -> Label) {
        self.destination = destination
        self.label = label()
    }

    var body: some View {
        NavigationLink {
            destination
                .environment(\.trackPath, currentPath)
        } label: {
            label
        }
    }
}
