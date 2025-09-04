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
class ExamScheduleViewModel: NSObject, ObservableObject {
    private var calendarHelper = CalendarHelper()

    @Published var availableSemesters: [String] = []
    @Published var errorMessage = ""
    @Published var warningMessage = ""
    @Published var data: ExamScheduleData? = nil

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

    var shareContent: UIImage? = nil
    var isLoaded: Bool = false

    func task(_ eduHelper: EduHelper?) {
        guard !isLoaded else { return }
        isLoaded = true
        loadAvailableSemesters(eduHelper)
        loadExams(eduHelper)
    }

    func loadAvailableSemesters(_ eduHelper: EduHelper?) {
        isSemestersLoading = true
        Task {
            defer {
                isSemestersLoading = false
            }

            do {
                (availableSemesters, selectedSemesters) = try await eduHelper?.examService.getAvailableSemestersForExamSchedule() ?? ([], nil)
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
                    startDate: exam.examStartTime,
                    endDate: exam.examEndTime,
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
        guard let exams = data?.exams else {
            errorMessage = "考试安排为空，无法添加到日历"
            isShowingError = true
            return
        }
        Task {
            do {
                let calendar = try await calendarHelper.getOrCreateCalendar(named: "考试")
                for exam in exams {
                    try await calendarHelper.addEvent(
                        title: "考试：\(exam.courseName)",
                        startDate: exam.examStartTime,
                        endDate: exam.examEndTime,
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

    private func saveDataToLocal(_ data: ExamScheduleData) {
        let context = SharedModel.context
        let examSchedules = try? context.fetch(FetchDescriptor<ExamSchedule>())
        examSchedules?.forEach { context.delete($0) }
        let examSchedule = ExamSchedule(data: data)
        context.insert(examSchedule)
        try? context.save()
    }

    private func loadDataFromLocal() {
        let context = SharedModel.context
        let examSchedules = try? context.fetch(FetchDescriptor<ExamSchedule>())
        guard let data = examSchedules?.first?.data else { return }
        self.data = data
    }

    func loadExams(_ eduHelper: EduHelper?) {
        isLoading = true
        Task {
            defer {
                isLoading = false
            }

            if let eduHelper = eduHelper {
                do {
                    let exams = try await eduHelper.examService.getExamSchedule(academicYearSemester: selectedSemesters, semesterType: selectedSemesterType)
                    data = ExamScheduleData.fromExams(exams: exams)
                    saveDataToLocal(data!)
                } catch {
                    errorMessage = error.localizedDescription
                    isShowingError = true

                    loadDataFromLocal()
                }
            } else {
                loadDataFromLocal()
                if let data = data {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.warningMessage = "教务系统未登录，使用 \(DateHelper.relativeTimeString(for: data.lastUpdated)) 的本地缓存数据"
                        self.isShowingWarning = true
                    }
                }
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
