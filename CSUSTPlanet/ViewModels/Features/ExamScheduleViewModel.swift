//
//  ExamScheduleViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/10.
//

import CSUSTKit
import Foundation

@MainActor
class ExamScheduleViewModel: ObservableObject {
    private var eduHelper: EduHelper?

    @Published var isShowingError = false
    @Published var errorMessage = ""

    @Published var isQuerying = false

    @Published var isSemestersLoading = false
    @Published var availableSemesters: [String] = []
    @Published var selectedSemesters: String? = nil
    @Published var selectedSemesterType: SemesterType? = nil

    @Published var examSchedule: [Exam] = []

    init(eduHelper: EduHelper?) {
        self.eduHelper = eduHelper
    }

    func loadAvailableSemesters() {
        guard let eduHelper = eduHelper else {
            errorMessage = "教务服务未初始化"
            isShowingError = true
            return
        }

        isSemestersLoading = true
        Task {
            defer {
                isSemestersLoading = false
            }

            do {
                (availableSemesters, selectedSemesters) = try await eduHelper.examService.getAvailableSemestersForExamSchedule()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func getExams() {
        guard let eduHelper = eduHelper else {
            errorMessage = "教务服务未初始化"
            isShowingError = true
            return
        }

        isQuerying = true
        Task {
            defer {
                isQuerying = false
            }
            do {
                examSchedule = try await eduHelper.examService.getExamSchedule(academicYearSemester: selectedSemesters, semesterType: selectedSemesterType)
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }
}
