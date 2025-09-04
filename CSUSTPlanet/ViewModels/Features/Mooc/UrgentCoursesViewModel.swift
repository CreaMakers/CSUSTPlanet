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
    @Published var data: UrgentCourseData? = nil

    @Published var isLoading = false
    @Published var isShowingError = false
    @Published var isShowingWarning = false

    var isLoaded: Bool = false

    private func saveDataToLocal(_ data: UrgentCourseData) {
        let context = SharedModel.context
        let urgentCourses = try? context.fetch(FetchDescriptor<UrgentCourse>())
        urgentCourses?.forEach { context.delete($0) }
        let urgentCourse = UrgentCourse(data: data)
        context.insert(urgentCourse)
        try? context.save()
    }

    private func loadDataFromLocal() {
        let context = SharedModel.context
        let urgentCourses = try? context.fetch(FetchDescriptor<UrgentCourse>())
        guard let data = urgentCourses?.first?.data else { return }
        self.data = data
    }

    func loadUrgentCourses(_ moocHelper: MoocHelper?) {
        isLoading = true
        Task {
            defer {
                isLoading = false
            }

            if let moocHelper = moocHelper {
                do {
                    let urgentCourses = try await moocHelper.getCourseNamesWithPendingHomeworks()
                    data = UrgentCourseData.fromCourses(urgentCourses)
                    saveDataToLocal(data!)
                } catch {
                    errorMessage = error.localizedDescription
                    isShowingError = true

                    loadDataFromLocal()
                }
            } else {
                loadDataFromLocal()
                if let data = data {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.warningMessage = "网络课程中心未登录，使用 \(DateHelper.relativeTimeString(for: data.lastUpdated)) 的本地缓存数据"
                        self.isShowingWarning = true
                    }
                }
            }
        }
    }
}
