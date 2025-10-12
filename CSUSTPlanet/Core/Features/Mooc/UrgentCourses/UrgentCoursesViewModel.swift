//
//  UrgentCoursesViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import Foundation
import SwiftData

@MainActor
class UrgentCoursesViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var warningMessage = ""
    @Published var data: Cached<UrgentCourseData>? = nil

    @Published var isLoading = false
    @Published var isShowingError = false
    @Published var isShowingWarning = false

    var isLoaded: Bool = false

    init() {
        loadDataFromLocal()
    }

    private func saveDataToLocal(_ data: Cached<UrgentCourseData>) {
        MMKVManager.shared.urgentCoursesCache = data
    }

    private func loadDataFromLocal(_ prompt: String? = nil) {
        guard let data = MMKVManager.shared.urgentCoursesCache else { return }
        self.data = data

        if let prompt = prompt {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.warningMessage = String(format: prompt, DateHelper.relativeTimeString(for: data.cachedAt))
                self.isShowingWarning = true
            }
        }
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
                    data = Cached(cachedAt: .now, value: UrgentCourseData.fromCourses(urgentCourses))
                    saveDataToLocal(data!)
                } catch {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            } else {
                loadDataFromLocal("网络课程中心未登录，已加载上次查询数据（%@）")
            }
        }
    }
}
