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
    @Published var isSimplified = false

    var courseInfo: MoocHelper.Course {
        return course
    }

    init(course: MoocHelper.Course) {
        self.course = course
        self.isSimplified = false
    }

    init(id: String, name: String) {
        self.course = MoocHelper.Course(id: id, number: "", name: name, department: "", teacher: "")
        self.isSimplified = true
    }

    func loadHomeworks() {
        isHomeworksLoading = true
        Task {
            defer {
                isHomeworksLoading = false
            }

            if let moocHelper = AuthManager.shared.moocHelper {
                do {
                    homeworks = try await moocHelper.getCourseHomeworks(courseId: course.id)
                } catch {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            } else {
                errorMessage = "请先等待网络课程中心登录完成后再重试"
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

            if let moocHelper = AuthManager.shared.moocHelper {
                do {
                    tests = try await moocHelper.getCourseTests(courseId: course.id)
                } catch {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            } else {
                errorMessage = "请先等待网络课程中心登录完成后再重试"
                isShowingError = true
            }
        }
    }
}
