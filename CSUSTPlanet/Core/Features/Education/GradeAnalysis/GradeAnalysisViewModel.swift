//
//  GradeAnalysisViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/12.
//

import CSUSTKit
import Foundation
import SwiftData
import SwiftUI
import WidgetKit

@MainActor
class GradeAnalysisViewModel: NSObject, ObservableObject {
    struct GradeAnalysisData {
        var totalCourses: Int
        var totalHours: Int
        var totalCredits: Double
        var overallAverageGrade: Double
        var overallGPA: Double
        var weightedAverageGrade: Double
        var gradePointDistribution: [(gradePoint: Double, count: Int)]
        var semesterAverageGrades: [(semester: String, average: Double)]
        var semesterGPAs: [(semester: String, gpa: Double)]
    }

    @Published var errorMessage: String = ""
    @Published var warningMessage: String = ""
    @Published var data: Cached<[EduHelper.CourseGrade]>?
    @Published var weightedAverageGrade: Double?

    @Published var isLoading: Bool = false
    @Published var isShowingWarning: Bool = false
    @Published var isShowingError: Bool = false
    @Published var isShowingSuccess: Bool = false
    @Published var isShowingShareSheet: Bool = false

    var analysisData: GradeAnalysisData? {
        guard let courseGrades = data?.value else { return nil }
        let totalCourses = courseGrades.count
        let totalHours = courseGrades.reduce(0) { $0 + $1.totalHours }
        let totalCredits = courseGrades.reduce(0) { $0 + $1.credit }
        let overallAverageGrade = totalCourses > 0 ? Double(courseGrades.reduce(0) { $0 + $1.grade }) / Double(totalCourses) : 0.0
        let overallGPA = totalCredits > 0 ? courseGrades.reduce(0) { $0 + $1.gradePoint * $1.credit } / totalCredits : 0.0
        let weightedAverageGrade = totalCredits > 0 ? courseGrades.reduce(0) { $0 + (Double($1.grade) * $1.credit) } / totalCredits : 0.0
        let gradePointDistribution = courseGrades.reduce(into: [Double: Int]()) { result, course in
            result[course.gradePoint, default: 0] += 1
        }.map { (gradePoint: $0.key, count: $0.value) }
        let semesterAverageGrades = Dictionary(grouping: courseGrades, by: { $0.semester }).map { semester, grades in
            (semester: semester, average: Double(grades.reduce(0) { $0 + $1.grade }) / Double(grades.count))
        }
        let semesterGPAs = Dictionary(grouping: courseGrades, by: { $0.semester }).map { semester, grades in
            let totalCredits = grades.reduce(0) { $0 + $1.credit }
            let totalGradePoints = grades.reduce(0) { $0 + $1.gradePoint * $1.credit }
            let gpa = totalCredits > 0 ? totalGradePoints / totalCredits : 0.0
            return (semester: semester, gpa: gpa)
        }
        return GradeAnalysisData(
            totalCourses: totalCourses,
            totalHours: totalHours,
            totalCredits: totalCredits,
            overallAverageGrade: overallAverageGrade,
            overallGPA: overallGPA,
            weightedAverageGrade: weightedAverageGrade,
            gradePointDistribution: gradePointDistribution.sorted { $0.gradePoint > $1.gradePoint },
            semesterAverageGrades: semesterAverageGrades.sorted { $0.semester < $1.semester },
            semesterGPAs: semesterGPAs.sorted { $0.semester < $1.semester }
        )
    }

    var shareContent: UIImage?

    override init() {
        super.init()
        loadDataFromLocal()
    }

    private func getDataFromRemote(_ eduHelper: EduHelper) async throws -> [EduHelper.CourseGrade] {
        return try await eduHelper.courseService.getCourseGrades()
    }

    private func saveDataToLocal(_ data: Cached<[EduHelper.CourseGrade]>) {
        MMKVManager.shared.courseGradesCache = data
    }

    private func loadDataFromLocal(_ prompt: String? = nil) {
        guard let data = MMKVManager.shared.courseGradesCache else { return }
        self.data = data

        if let prompt = prompt {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.warningMessage = String(format: prompt, DateHelper.relativeTimeString(for: data.cachedAt))
                self.isShowingWarning = true
            }
        }
    }

    func loadGradeAnalysis(_ eduHelper: EduHelper?) {
        isLoading = true
        Task {
            defer {
                isLoading = false
            }

            if let eduHelper = eduHelper {
                do {
                    let courseGrades = try await eduHelper.courseService.getCourseGrades()
                    data = Cached(cachedAt: .now, value: courseGrades)
                    saveDataToLocal(data!)
                    WidgetCenter.shared.reloadTimelines(ofKind: "GradeAnalysisWidget")
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
