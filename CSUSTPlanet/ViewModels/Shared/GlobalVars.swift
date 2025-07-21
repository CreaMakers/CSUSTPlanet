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
        isUserAgreementAccepted = UserDefaults.standard.bool(forKey: "isUserAgreementAccepted")
    }

    @Published var selectedTab: Int = 0
    @Published var appearance: String {
        didSet {
            UserDefaults.standard.set(appearance, forKey: "appearance")
        }
    }

    @Published var isUserAgreementAccepted: Bool {
        didSet {
            UserDefaults.standard.set(isUserAgreementAccepted, forKey: "isUserAgreementAccepted")
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

    @Published var isFromElectricityWidget: Bool = false
}
