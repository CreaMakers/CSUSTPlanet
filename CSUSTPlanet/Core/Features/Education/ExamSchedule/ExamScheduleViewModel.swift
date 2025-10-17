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
    private let calendarHelper = CalendarHelper()

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

    var shareContent: Any? = nil
    var isLoaded: Bool = false

    override init() {
        super.init()
        loadDataFromLocal()
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
                let calendar = try await calendarHelper.getOrCreateEventCalendar(named: "长理星球 - 考试")
                try await calendarHelper.addEvent(
                    calendar: calendar,
                    title: "考试：\(exam.courseName)",
                    startDate: exam.examStartTime,
                    endDate: exam.examEndTime,
                    notes: "课程老师：\(exam.teacher)",
                    location: exam.examRoom
                )
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
                let calendar = try await calendarHelper.getOrCreateEventCalendar(named: "长理星球 - 考试")
                for exam in exams {
                    try await calendarHelper.addEvent(
                        calendar: calendar,
                        title: "考试：\(exam.courseName)",
                        startDate: exam.examStartTime,
                        endDate: exam.examEndTime,
                        notes: "课程老师：\(exam.teacher)",
                        location: exam.examRoom
                    )
                }
                successMessage = "添加到日历成功"
                isShowingSuccess = true
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    private func saveDataToLocal(_ data: Cached<[EduHelper.Exam]>) {
        MMKVManager.shared.examSchedulesCache = data
    }

    private func loadDataFromLocal(_ prompt: String? = nil) {
        guard let data = MMKVManager.shared.examSchedulesCache else { return }
        self.data = data

        if let prompt = prompt {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.warningMessage = String(format: prompt, DateHelper.relativeTimeString(for: data.cachedAt))
                self.isShowingWarning = true
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
                    data = Cached<[EduHelper.Exam]>(cachedAt: .now, value: exams)
                    saveDataToLocal(data!)
                } catch {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            } else {
                loadDataFromLocal("教务系统未登录，已加载上次查询数据（%@）")
            }
        }
    }

    func showShareSheet(_ shareableView: some View) {
        let renderer = ImageRenderer(content: shareableView)
        renderer.scale = UIScreen.main.scale
        guard let uiImage = renderer.uiImage else {
            errorMessage = "生成图片失败"
            isShowingError = true
            return
        }
        shareContent = ImageActivityItemSource(title: "我的考试安排", image: uiImage)
        isShowingShareSheet = true
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
            successMessage = "图片保存成功"
            isShowingSuccess = true
        }
    }
}
