//
//  GlobalManager.swift
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
class GlobalManager: ObservableObject {
    public static let shared = GlobalManager()

    private init() {
        appearance = MMKVHelper.shared.appearance
        isUserAgreementAccepted = MMKVHelper.shared.isUserAgreementAccepted
        isLiveActivityEnabled = MMKVHelper.shared.isLiveActivityEnabled
        isWebVPNModeEnabled = MMKVHelper.shared.isWebVPNModeEnabled
        isNotificationEnabled = MMKVHelper.shared.isNotificationEnabled
    }

    @Published var selectedTab: TabItem = .overview
    @Published var appearance: String {
        didSet { MMKVHelper.shared.appearance = appearance }
    }
    @Published var isUserAgreementAccepted: Bool {
        didSet { MMKVHelper.shared.isUserAgreementAccepted = isUserAgreementAccepted }
    }
    var isUserAgreementShowing: Binding<Bool> {
        Binding(get: { !self.isUserAgreementAccepted }, set: { self.isUserAgreementAccepted = !$0 })
    }
    @Published var isLiveActivityEnabled: Bool {
        didSet { MMKVHelper.shared.isLiveActivityEnabled = isLiveActivityEnabled }
    }
    @Published var isWebVPNModeEnabled: Bool {
        didSet { MMKVHelper.shared.isWebVPNModeEnabled = isWebVPNModeEnabled }
    }
    @Published var isNotificationEnabled: Bool {
        didSet { MMKVHelper.shared.isNotificationEnabled = isNotificationEnabled }
    }

    @Published var isFromElectricityWidget: Bool = false
    @Published var isFromGradeAnalysisWidget: Bool = false
    @Published var isFromCourseScheduleWidget: Bool = false
    @Published var isFromUrgentCoursesWidget: Bool = false
}
