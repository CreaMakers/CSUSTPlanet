//
//  ExamScheduleViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/10.
//

import CSUSTKit
import Foundation
import SwiftData
import SwiftUI

@MainActor
class ExamScheduleViewModel: ObservableObject {
    @Published var availableSemesters: [String] = []
    @Published var errorMessage = ""
    @Published var warningMessage = ""
    @Published var successMessage = ""
    @Published var data: Cached<[EduHelper.Exam]>? = nil

    @Published var isShowingAddToCalendarAlert = false
    @Published var isShowingError = false
    @Published var isSemestersLoading = false
    @Published var isLoading = false
    @Published var isShowingFilter: Bool = false
    @Published var isShowingSuccess: Bool = false
    @Published var isShowingWarning: Bool = false
    @Published var isShowingShareSheet: Bool = false

    @Published var selectedSemesters: String? = nil
    @Published var selectedSemesterType: EduHelper.SemesterType? = nil

    var isLoaded: Bool = false

    init() {
        guard let data = MMKVManager.shared.examSchedulesCache else { return }
        self.data = data
    }

    func task() {
        guard !isLoaded else { return }
        isLoaded = true
        loadAvailableSemesters()
        loadExams()
    }

    func loadAvailableSemesters() {
        isSemestersLoading = true
        Task {
            defer {
                isSemestersLoading = false
            }

            do {
                (availableSemesters, selectedSemesters) = try await AuthManager.shared.eduHelper?.examService.getAvailableSemestersForExamSchedule() ?? ([], nil)
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func addToCalendar(exam: EduHelper.Exam) {
        Task {
            do {
                let calendar = try await CalendarHelper.getOrCreateEventCalendar(named: "长理星球 - 考试")
                try await CalendarHelper.addEvent(
                    calendar: calendar,
                    title: "考试：\(exam.courseName)",
                    startDate: exam.examStartTime,
                    endDate: exam.examEndTime,
                    notes: "课程老师：\(exam.teacher)",
                    location: exam.examRoom
                )
                successMessage = "已添加到日历"
                isShowingSuccess = true
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func addAllToCalendar() {
        guard let exams = data?.value else {
            errorMessage = "考试安排为空，无法添加到日历"
            isShowingError = true
            return
        }
        Task {
            do {
                let calendar = try await CalendarHelper.getOrCreateEventCalendar(named: "长理星球 - 考试")
                for exam in exams {
                    try await CalendarHelper.addEvent(
                        calendar: calendar,
                        title: "考试：\(exam.courseName)",
                        startDate: exam.examStartTime,
                        endDate: exam.examEndTime,
                        notes: "课程老师：\(exam.teacher)",
                        location: exam.examRoom
                    )
                }
                successMessage = "全部添加到日历成功"
                isShowingSuccess = true
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func loadExams() {
        isLoading = true
        Task {
            defer {
                isLoading = false
            }

            if let eduHelper = AuthManager.shared.eduHelper {
                do {
                    let exams = try await eduHelper.examService.getExamSchedule(academicYearSemester: selectedSemesters, semesterType: selectedSemesterType)
                    let sortedExams = exams.sorted {
                        return $0.examStartTime < $1.examStartTime
                    }

                    let data = Cached<[EduHelper.Exam]>(cachedAt: .now, value: sortedExams)
                    self.data = data
                    MMKVManager.shared.examSchedulesCache = data
                } catch {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            } else {
                guard let data = MMKVManager.shared.examSchedulesCache else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.warningMessage = "请先登录教务系统后再查询数据"
                        self.isShowingWarning = true
                    }
                    return
                }
                self.data = data
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.warningMessage = String(format: "教务系统未登录，\n已加载上次查询数据（%@）", DateHelper.relativeTimeString(for: data.cachedAt))
                    self.isShowingWarning = true
                }
            }
        }
    }
}
