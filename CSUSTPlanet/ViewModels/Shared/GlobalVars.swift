//
//  GlobalVars.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import Foundation

@MainActor
class GlobalVars: ObservableObject {
    public static let shared = GlobalVars()

    private init() {
        appearance = UserDefaults.standard.string(forKey: "appearance") ?? "system"
    }

    @Published var selectedTab: Int = 0
    @Published var appearance: String {
        didSet {
            UserDefaults.standard.set(appearance, forKey: "appearance")
        }
    }

    var isElectricityTermAccepted: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: "isElectricityTermAccepted")
        }
        get {
            UserDefaults.standard.bool(forKey: "isElectricityTermAccepted")
        }
    }
}
