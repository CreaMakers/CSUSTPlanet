//
//  CoursesView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/14.
//

import CSUSTKit
import SwiftUI

struct CoursesView: View {
    @State private var courses: [MoocHelper.Course] = []
    @State private var errorToast: ToastState = .errorTitle

    @State private var isLoading = false

    @State private var isInitial = true

    var body: some View {
        CoursesContent(
            courses: courses,
            isLoading: isLoading,
            errorToast: $errorToast,
            onRefreshCourses: loadCourses
        )
        .task {
            guard isInitial else {
                return
            }
            isInitial = false
            await loadCourses()
        }
    }

    // MARK: - Methods

    private func loadCourses() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            courses = try await AuthManager.shared.withAuthRetry(system: .mooc) {
                try await AuthManager.shared.moocHelper.getCourses()
            }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}
