//
//  ExamScheduleViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/10.
//

import CSUSTKit
import Combine
import Foundation
import SwiftUI

@MainActor
@Observable
class ExamScheduleViewModel {
    var availableSemesters: [String] = []
    var examData: Cached<[EduHelper.Exam]>? = nil

    var isLoadingSemesters: Bool = false
    var isLoadingExams: Bool = false

    var isAddToCalendarAlertPresented: Bool = false
    var isFilterPresented: Bool = false

    var selectedSemester: String? = nil
    var selectedSemesterType: EduHelper.SemesterType? = nil

    var errorToast: ToastState = .errorTitle
    var successToast: ToastState = .successTitle
    var loadingToast: ToastState = .init(title: "添加中")

    @ObservationIgnored var isInitial: Bool = true

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    init() {
        examData = MMKVHelper.ExamSchedule.cache

        MMKVHelper.ExamSchedule.$cache
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in self?.examData = data }
            .store(in: &cancellables)
    }

    func loadInitial() async {
        guard isInitial else { return }
        isInitial = false
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadAvailableSemesters() }
            group.addTask { await self.loadExams() }
        }
    }

    func loadAvailableSemesters() async {
        guard !isLoadingSemesters else { return }
        isLoadingSemesters = true
        defer { isLoadingSemesters = false }

        do {
            (availableSemesters, selectedSemester) = try await AuthManager.shared.withAuthRetry(system: .edu) {
                try await AuthManager.shared.eduHelper.examService.getAvailableSemestersForExamSchedule()
            }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func loadExams() async {
        guard !isLoadingExams else { return }
        isLoadingExams = true
        defer { isLoadingExams = false }

        do {
            let exams = try await AuthManager.shared.withAuthRetry(system: .edu) {
                try await AuthManager.shared.eduHelper.examService.getExamSchedule(academicYearSemester: self.selectedSemester, semesterType: self.selectedSemesterType)
            }
            let sortedExams = exams.sorted {
                return $0.examStartTime < $1.examStartTime
            }

            let data = Cached<[EduHelper.Exam]>(cachedAt: .now, value: sortedExams)
            MMKVHelper.ExamSchedule.cache = data
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func isExamFinished(_ exam: EduHelper.Exam) -> Bool {
        return .now > exam.examEndTime
    }

    func daysUntilExam(_ exam: EduHelper.Exam) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let examDay = calendar.startOfDay(for: exam.examStartTime)
        let components = calendar.dateComponents([.day], from: startOfDay, to: examDay)
        return components.day ?? 0
    }

    func addToCalendar() async {
        guard let exams = examData?.value, !exams.isEmpty else {
            errorToast.show(message: "考试安排为空，无法添加到日历")
            return
        }
        loadingToast.show(message: "正在添加到日历...")
        defer { loadingToast.hide() }
        do {
            let calendar = try await CalendarUtil.getOrCreateEventCalendar(named: "长理星球 - 考试")
            for exam in exams {
                try await CalendarUtil.addEvent(
                    calendar: calendar,
                    title: "考试：\(exam.courseName)",
                    startDate: exam.examStartTime,
                    endDate: exam.examEndTime,
                    notes: "课程老师：\(exam.teacher)",
                    location: exam.examRoom
                )
            }
            successToast.show(message: "全部添加到日历成功")
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}

extension MMKVHelper {
    enum ExamSchedule {
        @MMKVOptionalStorage(key: "Cached.examSchedulesCache")
        static var cache: Cached<[EduHelper.Exam]>?
    }
}
