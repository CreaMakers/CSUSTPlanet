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
    private var eduHelper: EduHelper

    @Published var courseGrade: EduHelper.CourseGrade

    @Published var isLoadingDetail = false

    @Published var isShowingError = false
    @Published var isShowingSuccess = false
    @Published var errorMessage: String = ""

    @Published var gradeDetail: EduHelper.GradeDetail?
    
    @Published var isShowingShareSheet = false
    var shareContent: UIImage? = nil

    init(eduHelper: EduHelper, courseGrade: EduHelper.CourseGrade) {
        self.eduHelper = eduHelper
        self.courseGrade = courseGrade
    }

    func loadDetail() {
        isLoadingDetail = true

        Task {
            defer {
                isLoadingDetail = false
            }

            do {
                gradeDetail = try await eduHelper.courseService.getGradeDetail(url: courseGrade.gradeDetailUrl)
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
