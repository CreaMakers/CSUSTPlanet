//
//  CoursesViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/14.
//

import CSUSTKit
import Foundation

@MainActor
class CoursesViewModel: ObservableObject {
    private var moocHelper: MoocHelper?

    @Published var courses: [MoocCourse] = []

    @Published var isShowingError = false
    @Published var errorMessage = ""

    @Published var isLoading = false
    @Published var loadingID = UUID()

    init(moocHelper: MoocHelper? = nil) {
        self.moocHelper = moocHelper
    }

    func loadCourses() {
        guard let moocHelper = moocHelper else {
            errorMessage = "网络课程中心服务未初始化"
            isShowingError = true
            return
        }

        isLoading = true
        loadingID = UUID()
        Task {
            defer {
                isLoading = false
            }

            do {
                courses = try await moocHelper.getCourses()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }
}
