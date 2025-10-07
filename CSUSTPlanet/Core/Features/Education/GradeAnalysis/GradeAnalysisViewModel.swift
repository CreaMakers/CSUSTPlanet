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
    @Published var data: Cached<[EduHelper.CourseGrade]>?
    @Published var weightedAverageGrade: Double?

    @Published var isLoading: Bool = false
    @Published var isShowingWarning: Bool = false
    @Published var isShowingError: Bool = false
    @Published var isShowingSuccess: Bool = false
    @Published var isShowingShareSheet: Bool = false

    var analysisData: GradeAnalysisData? {
        guard let courseGrades = data?.value else { return nil }
        return GradeAnalysisData.fromCourseGrades(courseGrades)
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
