//
//  GlobalVars.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import Foundation

@MainActor
class GlobalVars: ObservableObject {
    init() {
        appearance = UserDefaults.standard.string(forKey: "appearance") ?? "system"
    }

    @Published var selectedTab: Int = 0
    @Published var appearance: String {
        didSet {
            UserDefaults.standard.set(appearance, forKey: "appearance")
        }
    }
}
