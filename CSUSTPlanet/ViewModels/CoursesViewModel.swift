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
    private var moocHelper: MoocHelper

    @Published var courses: [MoocCourse] = []

    @Published var isShowingError = false
    @Published var errorMessage = ""

    @Published var isLoading = false
    @Published var loadingID = UUID()

    init(moocHelper: MoocHelper) {
        self.moocHelper = moocHelper
    }

    func loadCourses() {
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
