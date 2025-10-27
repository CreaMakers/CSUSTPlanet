//
//  GradeDetailViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/12.
//

import CSUSTKit
import Foundation
import SwiftUI

@MainActor
class GradeDetailViewModel: NSObject, ObservableObject {
    @Published var gradeDetail: EduHelper.GradeDetail?
    @Published var errorMessage: String = ""
    @Published var warningMessage: String = ""

    @Published var isLoading = false
    @Published var isShowingError = false
    @Published var isShowingSuccess = false
    @Published var isShowingWarning = false
    @Published var isShowingShareSheet = false

    var shareContent: Any? = nil

    func task(_ courseGrade: EduHelper.CourseGrade) {
        loadDetail(courseGrade)
    }

    func loadDetail(_ courseGrade: EduHelper.CourseGrade) {
        isLoading = true

        Task {
            defer {
                isLoading = false
            }
            if let eduHelper = AuthManager.shared.eduHelper {
                do {
                    gradeDetail = try await eduHelper.courseService.getGradeDetail(url: courseGrade.gradeDetailUrl)
                } catch {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.warningMessage = "请先登录教务系统后再查询数据"
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
        shareContent = ImageActivityItemSource(title: "我的成绩详情", image: uiImage)
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
