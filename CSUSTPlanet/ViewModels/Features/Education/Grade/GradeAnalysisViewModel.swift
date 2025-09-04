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
    @Published var errorMessage: String = ""
    @Published var warningMessage: String = ""
    @Published var data: GradeAnalysisData?
    @Published var weightedAverageGrade: Double?

    @Published var isLoading: Bool = false
    @Published var isShowingWarning: Bool = false
    @Published var isShowingError: Bool = false
    @Published var isShowingSuccess: Bool = false
    @Published var isShowingShareSheet: Bool = false

    var shareContent: UIImage?

    private func updateWeighedAverageGrade(_ courseGrades: [EduHelper.CourseGrade]) {
        let totalCredits = courseGrades.reduce(0) { $0 + $1.credit }
        if totalCredits > 0 {
            weightedAverageGrade = courseGrades.reduce(0) { $0 + (Double($1.grade) * $1.credit) } / totalCredits
        }
    }

    private func getDataFromRemote(_ eduHelper: EduHelper) async throws -> [EduHelper.CourseGrade] {
        return try await eduHelper.courseService.getCourseGrades()
    }

    private func saveDataToLocal(_ data: GradeAnalysisData) {
        let context = SharedModel.context
        let gradeAnalyses = try? context.fetch(FetchDescriptor<GradeAnalysis>())
        gradeAnalyses?.forEach { context.delete($0) }
        let gradeAnalysis = GradeAnalysis(data: data)
        context.insert(gradeAnalysis)
        try? context.save()
    }

    private func loadDataFromLocal() {
        let context = SharedModel.context
        let analyses = try? context.fetch(FetchDescriptor<GradeAnalysis>())
        guard let data = analyses?.first?.data else { return }
        self.data = data
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
                    data = GradeAnalysisData.fromCourseGrades(courseGrades)
                    saveDataToLocal(data!)
                    updateWeighedAverageGrade(courseGrades)
                    WidgetCenter.shared.reloadTimelines(ofKind: "GradeAnalysisWidget")
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
