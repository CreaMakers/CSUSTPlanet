//
//  GlobalVars.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import Foundation

enum TabItem: String {
    case home = "首页"
    case features = "全部功能"
    case profile = "我的"
}

@MainActor
class GlobalVars: ObservableObject {
    public static let shared = GlobalVars()

    private init() {
        appearance = UserDefaults.standard.string(forKey: "appearance") ?? "system"
        isUserAgreementAccepted = UserDefaults.standard.bool(forKey: "isUserAgreementAccepted")
    }

    @Published var selectedTab: TabItem = .home
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
    @Published var isFromGradeAnalysisWidget: Bool = false
    @Published var isFromCourseScheduleWidget: Bool = false
}
