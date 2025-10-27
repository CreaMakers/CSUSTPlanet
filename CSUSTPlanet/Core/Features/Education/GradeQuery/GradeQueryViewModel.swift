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
    // MARK: States

    @Published var availableSemesters: [String] = []
    @Published var data: Cached<[EduHelper.CourseGrade]>? = nil {
        didSet {
            updateAnalysis()
        }
    }
    @Published var analysis: GradeAnalysisData? = nil
    @Published var errorMessage: String = ""
    @Published var warningMessage: String = ""

    @Published var isLoading: Bool = false
    @Published var isSemestersLoading: Bool = false
    @Published var isShowingFilterPopover: Bool = false
    @Published var isShowingShareSheet: Bool = false

    @Published var isShowingSuccess: Bool = false
    @Published var isShowingError: Bool = false
    @Published var isShowingWarning: Bool = false

    @Published var searchText: String = ""
    @Published var selectedSemester: String = ""
    @Published var selectedCourseNature: EduHelper.CourseNature? = nil
    @Published var selectedDisplayMode: EduHelper.DisplayMode = .bestGrade
    @Published var selectedStudyMode: EduHelper.StudyMode = .major

    @Published var isSelectionMode: Bool = false {
        didSet {
            updateAnalysis()
        }
    }

    @Published var selectedCourseIDs = Set<String>() {
        didSet {
            if isSelectionMode {
                updateAnalysis()
            }
        }
    }

    var shareContent: Any? = nil
    var isLoaded: Bool = false

    var filteredCourseGrades: [EduHelper.CourseGrade] {
        guard let data = data else { return [] }
        if searchText.isEmpty {
            return data.value
        } else {
            return data.value.filter { $0.courseName.localizedCaseInsensitiveContains(searchText) }
        }
    }

    // MARK: - Methods

    func task() {
        guard !isLoaded else { return }
        isLoaded = true
        loadAvailableSemesters()
        loadCourseGrades()
    }

    private func updateAnalysis() {
        guard let allCourses = data?.value else {
            analysis = nil
            return
        }

        let coursesToAnalyze: [EduHelper.CourseGrade]

        if isSelectionMode {
            coursesToAnalyze = allCourses.filter { selectedCourseIDs.contains($0.courseID) }
        } else {
            coursesToAnalyze = allCourses
        }

        analysis = GradeAnalysisData.fromCourseGrades(coursesToAnalyze)
    }

    func enterSelectionMode() {
        isSelectionMode = true
        selectedCourseIDs = Set(filteredCourseGrades.map { $0.courseID })
    }

    func exitSelectionMode() {
        isSelectionMode = false
        selectedCourseIDs.removeAll()
    }

    func loadAvailableSemesters() {
        guard let eduHelper = AuthManager.shared.eduHelper else { return }
        isSemestersLoading = true
        Task {
            defer {
                isSemestersLoading = false
            }
            do {
                availableSemesters = try await eduHelper.courseService.getAvailableSemestersForCourseGrades()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func loadCourseGrades() {
        isLoading = true
        Task {
            defer {
                isLoading = false
            }
            if let eduHelper = AuthManager.shared.eduHelper {
                do {
                    let courseGrades = try await eduHelper.courseService.getCourseGrades(
                        academicYearSemester: selectedSemester,
                        courseNature: selectedCourseNature,
                        courseName: "",
                        displayMode: selectedDisplayMode,
                        studyMode: selectedStudyMode
                    )
                    let data = Cached(cachedAt: .now, value: courseGrades)
                    self.data = data
                    MMKVManager.shared.courseGradesCache = data
                    MMKVManager.shared.sync()
                } catch {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            } else {
                guard let data = MMKVManager.shared.courseGradesCache else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.warningMessage = "请先登录教务系统后再查询数据"
                        self.isShowingWarning = true
                    }
                    return
                }
                self.data = data
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.warningMessage = String(format: "教务系统未登录，\n已加载上次查询数据（%@）", DateHelper.relativeTimeString(for: data.cachedAt))
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
        shareContent = ImageActivityItemSource(title: "我的成绩单", image: uiImage)
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

    func exportGradesAsCSV() {
        guard let csvString = generateCSVString(from: filteredCourseGrades) else {
            errorMessage = "没有可导出的成绩数据"
            isShowingError = true
            return
        }

        guard let csvData = csvString.data(using: .utf8) else {
            errorMessage = "无法将CSV数据编码为UTF-8"
            isShowingError = true
            return
        }

        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileName = "成绩导出-\(Date().formatted(date: .numeric, time: .shortened)).csv"
        let sanitizedFileName = fileName.replacingOccurrences(of: "/", with: "-")
        let fileURL = temporaryDirectory.appendingPathComponent(sanitizedFileName)

        do {
            try csvData.write(to: fileURL)

            shareContent = fileURL
            isShowingShareSheet = true

        } catch {
            errorMessage = "无法保存临时的CSV文件: \(error.localizedDescription)"
            isShowingError = true
        }
    }

    private func generateCSVString(from courseGrades: [EduHelper.CourseGrade]) -> String? {
        guard !courseGrades.isEmpty else { return nil }
        let header = "开课学期,课程编号,课程名称,分组名,成绩,详细成绩链接,修读方式,成绩标识,学分,总学时,绩点,补重学期,考核方式,考试性质,课程属性,课程性质,课程类别\n"

        let rows = courseGrades.map { grade -> String in
            let semester = escapeCSVField(grade.semester)
            let courseID = escapeCSVField(grade.courseID)
            let courseName = escapeCSVField(grade.courseName)
            let groupName = escapeCSVField(grade.groupName)
            let gradeValue = "\(grade.grade)"
            let gradeDetailUrl = escapeCSVField(grade.gradeDetailUrl)
            let studyMode = escapeCSVField(grade.studyMode)
            let gradeIdentifier = escapeCSVField(grade.gradeIdentifier)
            let credit = "\(grade.credit)"
            let totalHours = "\(grade.totalHours)"
            let gradePoint = "\(grade.gradePoint)"
            let retakeSemester = escapeCSVField(grade.retakeSemester)
            let assessmentMethod = escapeCSVField(grade.assessmentMethod)
            let examNature = escapeCSVField(grade.examNature)
            let courseAttribute = escapeCSVField(grade.courseAttribute)
            let courseNature = escapeCSVField(grade.courseNature.rawValue)
            let courseCategory = escapeCSVField(grade.courseCategory)

            return [semester, courseID, courseName, groupName, gradeValue, gradeDetailUrl, studyMode, gradeIdentifier, credit, totalHours, gradePoint, retakeSemester, assessmentMethod, examNature, courseAttribute, courseNature, courseCategory].joined(separator: ",")
        }

        return header + rows.joined(separator: "\n")
    }

    private func escapeCSVField(_ field: String) -> String {
        var escapedField = field
        escapedField = escapedField.replacingOccurrences(of: "\"", with: "\"\"")
        if escapedField.contains(",") || escapedField.contains("\"") {
            escapedField = "\"\(escapedField)\""
        }
        return escapedField
    }
}
