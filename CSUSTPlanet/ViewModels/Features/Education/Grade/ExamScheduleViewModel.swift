//
//  ExamScheduleViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/10.
//

import CSUSTKit
import Foundation
import SwiftUI

@MainActor
class ExamScheduleViewModel: NSObject, ObservableObject {
    private var eduHelper: EduHelper

    private var calendarHelper = CalendarHelper()

    @Published var isShowingAddToCalendarAlert = false
    @Published var isShowingError = false
    @Published var errorMessage = ""

    @Published var isQuerying = false
    @Published var queryID = UUID()

    @Published var isSemestersLoading = false
    @Published var availableSemesters: [String] = []
    @Published var selectedSemesters: String? = nil
    @Published var selectedSemesterType: EduHelper.SemesterType? = nil

    @Published var examSchedule: [EduHelper.Exam] = []

    @Published var isShowingFilter: Bool = false

    @Published var isShowingSuccess: Bool = false

    @Published var isShowingShareSheet: Bool = false
    var shareContent: UIImage? = nil

    var isLoaded: Bool = false

    init(eduHelper: EduHelper) {
        self.eduHelper = eduHelper
        super.init()
    }

    func task() {
        guard !isLoaded else { return }
        isLoaded = true
        loadAvailableSemesters()
        getExams()
    }

    func loadAvailableSemesters() {
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

    func addToCalendar(exam: EduHelper.Exam) {
        Task {
            do {
                let calendar = try await calendarHelper.getOrCreateCalendar(named: "考试")
                try await calendarHelper.addEvent(
                    title: "考试：\(exam.courseName)",
                    startDate: exam.examTimeRange.start,
                    endDate: exam.examTimeRange.end,
                    notes: exam.teacher,
                    location: exam.examRoom,
                    calendar: calendar
                )
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
                let calendar = try await calendarHelper.getOrCreateCalendar(named: "考试")
                for exam in examSchedule {
                    try await calendarHelper.addEvent(
                        title: "考试：\(exam.courseName)",
                        startDate: exam.examTimeRange.start,
                        endDate: exam.examTimeRange.end,
                        notes: exam.teacher,
                        location: exam.examRoom,
                        calendar: calendar
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func getExams() {
        isQuerying = true
        queryID = UUID()
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

    func showShareSheet(_ shareableView: some View) {
        let renderer = ImageRenderer(content: shareableView)
        renderer.scale = UIScreen.main.scale
        if let uiImage = renderer.uiImage {
            shareContent = uiImage
            isShowingShareSheet = true
        } else {
            errorMessage = "生成图片失败"
            isShowingError = true
        }
    }

    func saveToPhotoAlbum(_ shareableView: some View) {
        let renderer = ImageRenderer(content: shareableView)
        renderer.scale = UIScreen.main.scale
        if let uiImage = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(uiImage, self, #selector(saveToPhotoAlbumCallback(_:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            errorMessage = "生成图片失败"
            isShowingError = true
        }
    }

    @objc
    func saveToPhotoAlbumCallback(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            errorMessage = "保存图片失败，可能是没有权限: \(error.localizedDescription)"
            isShowingError = true
        } else {
            isShowingSuccess = true
        }
    }
}
