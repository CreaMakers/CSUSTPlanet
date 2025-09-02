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
    @Published var courseGrades: [EduHelper.CourseGrade] = []
    @Published var stats: (gpa: Double, totalCredits: Double, weightedAverageGrade: Double, averageGrade: Double, courseCount: Int)? = nil
    @Published var errorMessage: String = ""

    @Published var isLoading: Bool = false
    @Published var isSemestersLoading: Bool = false
    @Published var isShowingError: Bool = false
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
        if searchText.isEmpty {
            return courseGrades
        } else {
            return courseGrades.filter { $0.courseName.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private func updateStats() {
        let totalCredits = courseGrades.reduce(0) { $0 + $1.credit }
        if courseGrades.isEmpty || totalCredits == 0 {
            stats = nil
            return
        }
        let totalGradePoints = courseGrades.reduce(0) { $0 + $1.gradePoint * $1.credit }
        let gpa = totalCredits > 0 ? totalGradePoints / totalCredits : 0
        let totalGrades = courseGrades.reduce(0) { $0 + $1.grade }
        let weightedAverageGrade = courseGrades.reduce(0) { $0 + Double($1.grade) * $1.credit } / totalCredits
        let averageGrade = courseGrades.isEmpty ? 0 : Double(totalGrades) / Double(courseGrades.count)

        stats = (
            gpa: gpa,
            totalCredits: totalCredits,
            weightedAverageGrade: weightedAverageGrade,
            averageGrade: averageGrade,
            courseCount: courseGrades.count
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

    private func getCourseGrades(_ eduHelper: EduHelper?) async throws -> [EduHelper.CourseGrade] {
        let context = SharedModel.context
        let gradeQueries = try context.fetch(FetchDescriptor<GradeQuery>())
        if let eduHelper = eduHelper {
            let courseGrades = try await eduHelper.courseService.getCourseGrades(
                academicYearSemester: selectedSemester,
                courseNature: selectedCourseNature,
                courseName: "",
                displayMode: selectedDisplayMode,
                studyMode: selectedStudyMode
            )
            gradeQueries.forEach { context.delete($0) }
            let gradeQuery = GradeQuery(data: GradeQueryData.fromCourseGrades(courseGrades: courseGrades))
            context.insert(gradeQuery)
            try context.save()
            return courseGrades
        } else {
            guard let gradeQuery = gradeQueries.first else { return [] }
            return gradeQuery.data.courseGrades
        }
    }

    func loadCourseGrades(_ eduHelper: EduHelper?) {
        isLoading = true
        Task {
            defer {
                isLoading = false
            }

            do {
                courseGrades = try await getCourseGrades(eduHelper)
                updateStats()
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
