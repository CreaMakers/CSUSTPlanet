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
    private var eduHelper: EduHelper

    @Published var isQuerying: Bool = false

    @Published var isShowingError: Bool = false
    @Published var errorMessage: String = ""

    @Published var gradeAnalysisData: GradeAnalysisData?
    @Published var weightedAverageGrade: Double?

    @Published var isShowingSuccess: Bool = false
    @Published var isShowingShareSheet: Bool = false
    var shareContent: UIImage?

    init(eduHelper: EduHelper) {
        self.eduHelper = eduHelper
    }

    func getCourseGrades() {
        isQuerying = true
        Task {
            defer {
                isQuerying = false
            }

            do {
                let courseGrades = try await eduHelper.courseService.getCourseGrades()
                let gradeAnalysisData = GradeAnalysisData.fromCourseGrades(courseGrades)

                let totalCredits = courseGrades.reduce(0) { $0 + $1.credit }
                if totalCredits > 0 {
                    weightedAverageGrade = courseGrades.reduce(0) { $0 + (Double($1.grade) * $1.credit) } / totalCredits
                } else {
                    weightedAverageGrade = 0
                }
                self.gradeAnalysisData = gradeAnalysisData

                if !courseGrades.isEmpty {
                    let context = SharedModel.context

                    let analyses = try context.fetch(FetchDescriptor<GradeAnalysis>())
                    for analysis in analyses {
                        context.delete(analysis)
                    }
                    let gradeAnalysis = GradeAnalysis(data: gradeAnalysisData)
                    context.insert(gradeAnalysis)
                    try context.save()

                    WidgetCenter.shared.reloadTimelines(ofKind: "GradeAnalysisWidget")
                }
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
