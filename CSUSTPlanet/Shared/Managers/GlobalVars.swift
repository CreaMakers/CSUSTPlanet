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
        appearance = MMKVManager.shared.appearance
        isUserAgreementAccepted = MMKVManager.shared.isUserAgreementAccepted
        isLiveActivityEnabled = MMKVManager.shared.isLiveActivityEnabled
    }

    @Published var selectedTab: TabItem = .home
    @Published var appearance: String {
        didSet { MMKVManager.shared.appearance = appearance }
    }
    @Published var isUserAgreementAccepted: Bool {
        didSet { MMKVManager.shared.isUserAgreementAccepted = isUserAgreementAccepted }
    }
    var isUserAgreementShowing: Binding<Bool> {
        Binding(get: { !self.isUserAgreementAccepted }, set: { self.isUserAgreementAccepted = !$0 })
    }
    @Published var isLiveActivityEnabled: Bool {
        didSet { MMKVManager.shared.isLiveActivityEnabled = isLiveActivityEnabled }
    }

    @Published var isFromElectricityWidget: Bool = false
    @Published var isFromGradeAnalysisWidget: Bool = false
    @Published var isFromCourseScheduleWidget: Bool = false
}
