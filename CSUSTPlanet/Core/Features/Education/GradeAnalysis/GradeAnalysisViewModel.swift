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

    var shareContent: Any?

    override init() {
        super.init()
        guard let data = MMKVHelper.shared.courseGradesCache else { return }
        self.data = data
    }

    func task() {
        loadGradeAnalysis()
    }

    func loadGradeAnalysis() {
        isLoading = true
        Task {
            defer {
                isLoading = false
            }

            if let eduHelper = AuthManager.shared.eduHelper {
                do {
                    let courseGrades = try await eduHelper.courseService.getCourseGrades()
                    let data = Cached(cachedAt: .now, value: courseGrades)
                    self.data = data
                    MMKVHelper.shared.courseGradesCache = data
                    WidgetCenter.shared.reloadTimelines(ofKind: "GradeAnalysisWidget")
                } catch {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            } else {
                guard let data = MMKVHelper.shared.courseGradesCache else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.warningMessage = "请先登录教务系统后再查询数据"
                        self.isShowingWarning = true
                    }
                    return
                }
                self.data = data
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.warningMessage = String(format: "教务系统未登录，\n已加载上次查询数据（%@）", DateUtil.relativeTimeString(for: data.cachedAt))
                    self.isShowingWarning = true
                }
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
        shareContent = ImageActivityItemSource(title: "我的成绩分析", image: uiImage)
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
            isShowingSuccess = true
        }
    }
}
