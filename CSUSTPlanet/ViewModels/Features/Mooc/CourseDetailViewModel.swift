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
    @Published var homeworks: [MoocHelper.Homework] = []
    @Published var tests: [MoocHelper.Test] = []
    @Published var errorMessage = ""

    @Published var isShowingError = false
    @Published var isHomeworksLoading = false
    @Published var isTestsLoading = false

    private var course: MoocHelper.Course

    var courseInfo: MoocHelper.Course {
        return course
    }

    init(course: MoocHelper.Course) {
        self.course = course
    }

    func loadHomeworks(_ moocHelper: MoocHelper?) {
        isHomeworksLoading = true
        Task {
            defer {
                isHomeworksLoading = false
            }

            do {
                homeworks = try await moocHelper!.getCourseHomeworks(courseId: course.id)
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func loadTests(_ moocHelper: MoocHelper?) {
        isTestsLoading = true
        Task {
            defer {
                isTestsLoading = false
            }

            do {
                tests = try await moocHelper!.getCourseTests(courseId: course.id)
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }
}
