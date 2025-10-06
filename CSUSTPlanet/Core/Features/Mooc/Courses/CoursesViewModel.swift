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
    @Published var errorMessage = ""
    @Published var courses: [MoocHelper.Course] = []
    @Published var searchText: String = ""

    @Published var isShowingError = false
    @Published var isLoading = false

    var isLoaded = false

    var filteredCourses: [MoocHelper.Course] {
        if searchText.isEmpty {
            return courses
        } else {
            return courses.filter { course in
                course.name.localizedCaseInsensitiveContains(searchText) || course.teacher.localizedCaseInsensitiveContains(searchText) || course.department.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    func loadCourses(_ moocHelper: MoocHelper?) {
        isLoading = true
        Task {
            defer {
                isLoading = false
            }

            do {
                courses = try await moocHelper!.getCourses()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }
}
