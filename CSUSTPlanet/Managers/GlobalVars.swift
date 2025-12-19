//
//  GlobalVars.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import Foundation
import SwiftUI

enum TabItem: String {
    case overview = "概览"
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
        isWebVPNModeEnabled = MMKVManager.shared.isWebVPNModeEnabled
        isNotificationEnabled = MMKVManager.shared.isNotificationEnabled
    }

    @Published var selectedTab: TabItem = .overview
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
    @Published var isWebVPNModeEnabled: Bool {
        didSet { MMKVManager.shared.isWebVPNModeEnabled = isWebVPNModeEnabled }
    }
    @Published var isNotificationEnabled: Bool {
        didSet { MMKVManager.shared.isNotificationEnabled = isNotificationEnabled }
    }

    @Published var isFromElectricityWidget: Bool = false
    @Published var isFromGradeAnalysisWidget: Bool = false
    @Published var isFromCourseScheduleWidget: Bool = false
}
