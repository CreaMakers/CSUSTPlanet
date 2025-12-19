//
//  UrgentCoursesViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import Foundation
import SwiftData
import WidgetKit

@MainActor
class UrgentCoursesViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var warningMessage = ""
    @Published var data: Cached<UrgentCoursesData>? = nil

    @Published var isLoading = false
    @Published var isShowingError = false
    @Published var isShowingWarning = false

    var isLoaded: Bool = false

    init() {
        guard let data = MMKVHelper.shared.urgentCoursesCache else { return }
        self.data = data
    }

    func loadUrgentCourses() {
        isLoading = true
        Task {
            defer {
                isLoading = false
            }

            if let moocHelper = AuthManager.shared.moocHelper {
                do {
                    let urgentCourses = try await moocHelper.getCourseNamesWithPendingHomeworks()
                    let data = Cached(cachedAt: .now, value: UrgentCoursesData.fromCourses(urgentCourses))
                    self.data = data
                    MMKVHelper.shared.urgentCoursesCache = data
                    MMKVHelper.shared.sync()
                    WidgetCenter.shared.reloadTimelines(ofKind: "UrgentCoursesWidget")
                } catch {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            } else {
                guard let data = MMKVHelper.shared.urgentCoursesCache else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.warningMessage = "请先登录网络课程中心后再查询数据"
                        self.isShowingWarning = true
                    }
                    return
                }
                self.data = data
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.warningMessage = String(format: "网络课程中心未登录，\n已加载上次查询数据（%@）", DateUtil.relativeTimeString(for: data.cachedAt))
                    self.isShowingWarning = true
                }
            }
        }
    }
}
