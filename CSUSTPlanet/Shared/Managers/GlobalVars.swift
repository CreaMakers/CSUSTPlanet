//
//  GlobalVars.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import Foundation
import SwiftUI

enum TabItem: String {
    case home = "首页"
    case features = "全部功能"
    case profile = "我的"
}

@MainActor
class GlobalVars: ObservableObject {
    public static let shared = GlobalVars()

    private init() {
        appearance = MMKVManager.shared.string(forKey: "GlobalVars.appearance") ?? "system"
        isUserAgreementAccepted = MMKVManager.shared.bool(forKey: "GlobalVars.isUserAgreementAccepted") ?? false
    }

    @Published var selectedTab: TabItem = .home
    @Published var appearance: String {
        didSet { MMKVManager.shared.set(forKey: "GlobalVars.appearance", appearance) }
    }
    @Published var isUserAgreementAccepted: Bool {
        didSet { MMKVManager.shared.set(forKey: "GlobalVars.isUserAgreementAccepted", isUserAgreementAccepted) }
    }
    var isUserAgreementShowing: Binding<Bool> {
        Binding(get: { !self.isUserAgreementAccepted }, set: { self.isUserAgreementAccepted = !$0 })
    }

    var isElectricityTermAccepted: Bool {
        set { MMKVManager.shared.set(forKey: "GlobalVars.isElectricityTermAccepted", newValue) }
        get { MMKVManager.shared.bool(forKey: "GlobalVars.isElectricityTermAccepted") ?? false }
    }

    @Published var isFromElectricityWidget: Bool = false
    @Published var isFromGradeAnalysisWidget: Bool = false
    @Published var isFromCourseScheduleWidget: Bool = false
}
