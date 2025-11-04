//
//  PhysicsExperimentGradeViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/11/4.
//

import CSUSTKit
import Foundation

@MainActor
class PhysicsExperimentGradeViewModel: ObservableObject {
    @Published var warningMessage = ""
    @Published var data: [PhysicsExperimentHelper.CourseGrade] = []

    @Published var isLoading = false
    @Published var isShowingError = false
    @Published var isLoaded = false

    func loadGrades() {
        isLoading = true
        Task {
            defer {
                isLoading = false
            }
            do {
                self.data = try await PhysicsExperimentManager.shared.physicsExperimentHelper.getCourseGrades()
            } catch {
                warningMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }
}
