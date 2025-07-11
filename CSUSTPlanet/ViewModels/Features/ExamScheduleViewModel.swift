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

    private var calendarHelper = CalendarHelper()

    @Published var isShowingAddToCalendarAlert = false
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

    func addToCalendar(exam: Exam) {
        Task {
            do {
                try await calendarHelper.addEvent(title: exam.courseName, startDate: exam.examTimeRange.start, endDate: exam.examTimeRange.end, notes: exam.teacher, location: exam.examRoom)
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func addAllToCalendar() {
        guard !examSchedule.isEmpty else {
            errorMessage = "考试安排为空，无法添加到日历"
            isShowingError = true

            return
        }
        Task {
            do {
                for exam in examSchedule {
                    try await calendarHelper.addEvent(title: exam.courseName, startDate: exam.examTimeRange.start, endDate: exam.examTimeRange.end, notes: exam.teacher, location: exam.examRoom)
                }
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
