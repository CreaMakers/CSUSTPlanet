//
//  CourseDetailViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/8/23.
//

import CSUSTKit
import Foundation

@MainActor
class CourseDetailViewModel: ObservableObject {
    private var moocHelper: MoocHelper
    private var course: MoocHelper.Course

    @Published var isShowingError = false
    @Published var errorMessage = ""

    @Published var isHomeworksLoading = false
    @Published var isTestsLoading = false

    @Published var homeworks: [MoocHelper.Homework] = []
    @Published var tests: [MoocHelper.Test] = []

    init(moocHelper: MoocHelper, course: MoocHelper.Course) {
        self.moocHelper = moocHelper
        self.course = course
    }

    var courseInfo: MoocHelper.Course {
        return course
    }

    func loadHomeworks() {
        isHomeworksLoading = true
        Task {
            defer {
                isHomeworksLoading = false
            }

            do {
                homeworks = try await moocHelper.getCourseHomeworks(courseId: course.id)
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func loadTests() {
        isTestsLoading = true
        Task {
            defer {
                isTestsLoading = false
            }

            do {
                tests = try await moocHelper.getCourseTests(courseId: course.id)
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }
}
