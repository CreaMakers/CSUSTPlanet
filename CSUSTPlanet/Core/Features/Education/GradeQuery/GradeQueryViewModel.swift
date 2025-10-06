//
//  GradeQueryViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import CSUSTKit
import Foundation
import SwiftData
import SwiftUI

@MainActor
class GradeQueryViewModel: NSObject, ObservableObject {
    @Published var availableSemesters: [String] = []
    @Published var data: Cached<[EduHelper.CourseGrade]>? = nil
    @Published var stats: (gpa: Double, totalCredits: Double, weightedAverageGrade: Double, averageGrade: Double, courseCount: Int)? = nil
    @Published var errorMessage: String = ""
    @Published var warningMessage: String = ""

    @Published var isLoading: Bool = false
    @Published var isSemestersLoading: Bool = false
    @Published var isShowingError: Bool = false
    @Published var isShowingWarning: Bool = false
    @Published var isShowingFilterPopover: Bool = false
    @Published var isShowingSuccess: Bool = false
    @Published var isShowingShareSheet: Bool = false

    @Published var searchText: String = ""
    @Published var selectedSemester: String = ""
    @Published var selectedCourseNature: EduHelper.CourseNature? = nil
    @Published var selectedDisplayMode: EduHelper.DisplayMode = .bestGrade
    @Published var selectedStudyMode: EduHelper.StudyMode = .major

    var shareContent: UIImage? = nil
    var isLoaded: Bool = false

    var filteredCourseGrades: [EduHelper.CourseGrade] {
        guard let data = data else { return [] }
        if searchText.isEmpty {
            return data.value
        } else {
            return data.value.filter { $0.courseName.localizedCaseInsensitiveContains(searchText) }
        }
    }

    override init() {
        super.init()
        loadDataFromLocal()
    }

    private func updateStats() {
        guard let data = data else { return }
        let totalCredits = data.value.reduce(0) { $0 + $1.credit }
        if data.value.isEmpty || totalCredits == 0 {
            stats = nil
            return
        }
        let totalGradePoints = data.value.reduce(0) { $0 + $1.gradePoint * $1.credit }
        let gpa = totalCredits > 0 ? totalGradePoints / totalCredits : 0
        let totalGrades = data.value.reduce(0) { $0 + $1.grade }
        let weightedAverageGrade = data.value.reduce(0) { $0 + Double($1.grade) * $1.credit } / totalCredits
        let averageGrade = data.value.isEmpty ? 0 : Double(totalGrades) / Double(data.value.count)

        stats = (
            gpa: gpa,
            totalCredits: totalCredits,
            weightedAverageGrade: weightedAverageGrade,
            averageGrade: averageGrade,
            courseCount: data.value.count
        )
    }

    func task(_ eduHelper: EduHelper?) {
        guard !isLoaded else { return }
        isLoaded = true
        loadAvailableSemesters(eduHelper)
        loadCourseGrades(eduHelper)
    }

    func loadAvailableSemesters(_ eduHelper: EduHelper?) {
        isSemestersLoading = true
        Task {
            defer {
                isSemestersLoading = false
            }

            do {
                availableSemesters = try await eduHelper?.courseService.getAvailableSemestersForCourseGrades() ?? []
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    private func getDataFromRemote(_ eduHelper: EduHelper) async throws -> [EduHelper.CourseGrade] {
        return try await eduHelper.courseService.getCourseGrades(
            academicYearSemester: selectedSemester,
            courseNature: selectedCourseNature,
            courseName: "",
            displayMode: selectedDisplayMode,
            studyMode: selectedStudyMode
        )
    }

    private func saveDataToLocal(_ data: Cached<[EduHelper.CourseGrade]>) {
        MMKVManager.shared.courseGradesCache = data
    }

    private func loadDataFromLocal(_ prompt: String? = nil) {
        guard let data = MMKVManager.shared.courseGradesCache else { return }
        self.data = data
        updateStats()

        if let prompt = prompt {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.warningMessage = String(format: prompt, DateHelper.relativeTimeString(for: data.cachedAt))
                self.isShowingWarning = true
            }
        }
    }

    func loadCourseGrades(_ eduHelper: EduHelper?) {
        isLoading = true
        Task {
            defer {
                isLoading = false
            }

            if let eduHelper = eduHelper {
                do {
                    let courseGrades = try await getDataFromRemote(eduHelper)
                    data = Cached(cachedAt: .now, value: courseGrades)
                    saveDataToLocal(data!)
                    updateStats()
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
