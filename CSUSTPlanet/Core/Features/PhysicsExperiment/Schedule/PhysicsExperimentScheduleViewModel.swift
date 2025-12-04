//
//  PhysicsExperimentScheduleViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/11/4.
//

import CSUSTKit
import Foundation

@MainActor
class PhysicsExperimentScheduleViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var warningMessage = ""
    @Published var data: Cached<[PhysicsExperimentHelper.Course]>? = nil

    @Published var isLoading = false
    @Published var isShowingError = false
    @Published var isShowingWarning = false
    @Published var isLoaded = false

    init() {
        guard let data = MMKVManager.shared.physicsExperimentScheduleCache else { return }
        self.data = data
    }

    func loadSchedules() {
        isLoading = true
        Task {
            defer {
                isLoading = false
            }
            do {
                let schedules = try await PhysicsExperimentManager.shared.getCourses()
                let data = Cached(cachedAt: .now, value: schedules)
                self.data = data
                MMKVManager.shared.physicsExperimentScheduleCache = data
            } catch {
                if case PhysicsExperimentHelper.PhysicsExperimentError.notLoggedIn(_) = error {
                    if let cachedData = MMKVManager.shared.physicsExperimentScheduleCache {
                        self.data = cachedData
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.warningMessage = String(format: "未登录大物实验，\n已加载上次查询数据（%@）", DateHelper.relativeTimeString(for: cachedData.cachedAt))
                            self.isShowingWarning = true
                        }
                    } else {
                        errorMessage = error.localizedDescription
                        isShowingError = true
                    }
                } else {
                    if let cachedData = MMKVManager.shared.physicsExperimentScheduleCache {
                        self.data = cachedData
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.warningMessage = String(format: "错误：(%@)，\n已加载上次查询数据（%@）", error.localizedDescription, DateHelper.relativeTimeString(for: cachedData.cachedAt))
                            self.isShowingWarning = true
                        }
                    } else {
                        errorMessage = error.localizedDescription
                        isShowingError = true
                    }
                }
            }
        }
    }
}
