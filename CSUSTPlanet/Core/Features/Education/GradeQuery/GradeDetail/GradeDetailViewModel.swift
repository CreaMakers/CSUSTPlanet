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
    @Published var courseGrade: EduHelper.CourseGrade
    @Published var gradeDetail: EduHelper.GradeDetail?
    @Published var errorMessage: String = ""

    @Published var isLoading = false
    @Published var isShowingError = false
    @Published var isShowingSuccess = false
    @Published var isShowingShareSheet = false

    var shareContent: UIImage? = nil

    init(_ courseGrade: EduHelper.CourseGrade) {
        self.courseGrade = courseGrade
    }

    func task() {
        if AuthManager.shared.eduHelper != nil {
            loadDetail()
        }
    }

    func loadDetail() {
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
                errorMessage = "请先等待教务系统登录完成后再重试"
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
