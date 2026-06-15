//
//  GradeQueryViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import CSUSTKit
import Combine
import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
@Observable
class GradeQueryViewModel {
    struct SelectionItem: Hashable {
        let course: String
    }

    // MARK: States

    var gradeData: Cached<[EduHelper.CourseGrade]>? = nil
    var gradeAnalysis: GradeAnalysisData? = nil
    private(set) var filteredGrades: [EduHelper.CourseGrade] = []
    private(set) var groupedFilteredGrades: [(semester: String, grades: [EduHelper.CourseGrade])] = []
    var semesterGPAs: [String: Double] = [:]

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    var searchText: String = "" {
        didSet { updateFilteredGrades() }
    }

    var isLoadingGrades: Bool = false

    var errorToast = ToastState()

    var isSelectionMode: Bool = false {
        didSet { updateAnalysis() }
    }
    var selectedItems = Set<SelectionItem>() {
        didSet { if isSelectionMode { updateAnalysis() } }
    }
    var expandedSemesters: Set<String> = []

    var shareContent: Any? = nil
    var isShareSheetPresented: Bool = false

    @ObservationIgnored var isInitial: Bool = true

    // MARK: - Methods

    init() {
        applyGradeData(MMKVHelper.CourseGrades.cache)

        MMKVHelper.CourseGrades.$cache
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.applyGradeData(data)
            }
            .store(in: &cancellables)
    }

    func loadInitial() async {
        guard isInitial else { return }
        isInitial = false
        await loadCourseGrades()
    }

    func loadCourseGrades() async {
        guard !isLoadingGrades else { return }
        isLoadingGrades = true
        defer { isLoadingGrades = false }

        do {
            let courseGrades = try await AuthManager.shared.withAuthRetry(system: .edu) {
                try await AuthManager.shared.eduHelper.courseService.getCourseGrades(academicYearSemester: nil, courseNature: nil, courseName: "")
            }
            let data = Cached(cachedAt: .now, value: courseGrades)
            MMKVHelper.CourseGrades.cache = data
            WidgetTimelineRefreshHelper.reloadGradeAnalysis()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    // MARK: - Expand Semesters

    func toggleExpandSemester(_ semester: String) {
        withAnimation {
            if expandedSemesters.contains(semester) {
                expandedSemesters.remove(semester)
            } else {
                expandedSemesters.insert(semester)
            }
        }
    }

    // MARK: - Selection Mode

    func enterSelectionMode() {
        selectedItems = Set(filteredGrades.map { SelectionItem(course: $0.courseID) })
        isSelectionMode = true
    }

    func exitSelectionMode() {
        isSelectionMode = false
        selectedItems.removeAll()
    }

    func selectAll() {
        selectedItems = Set(filteredGrades.map { SelectionItem(course: $0.courseID) })
    }

    func selectNone() {
        selectedItems.removeAll()
    }

    func toggleSelection(for courseID: String) {
        let item = SelectionItem(course: courseID)
        withAnimation {
            if selectedItems.contains(item) {
                selectedItems.remove(item)
            } else {
                selectedItems.insert(item)
            }
        }
    }

    func isSelected(_ courseID: String) -> Bool {
        selectedItems.contains(SelectionItem(course: courseID))
    }

    private func applyGradeData(_ data: Cached<[EduHelper.CourseGrade]>?) {
        gradeData = data

        guard let data else {
            expandedSemesters = []
            semesterGPAs = [:]
            filteredGrades = []
            groupedFilteredGrades = []
            gradeAnalysis = nil
            return
        }

        expandedSemesters = Set(data.value.map { $0.semester })
        semesterGPAs = computeSemesterGPAs(data.value)
        updateFilteredGrades()
        updateAnalysis()
    }

    private func computeSemesterGPAs(_ grades: [EduHelper.CourseGrade]) -> [String: Double] {
        Dictionary(grouping: grades, by: { $0.semester }).reduce(into: [:]) { result, entry in
            let totalCredits = entry.value.reduce(0) { $0 + $1.credit }
            let totalGradePoints = entry.value.reduce(0) { $0 + $1.gradePoint * $1.credit }
            result[entry.key] = totalCredits > 0 ? totalGradePoints / totalCredits : 0.0
        }
    }

    private func updateFilteredGrades() {
        guard let data = gradeData else {
            filteredGrades = []
            groupedFilteredGrades = []
            return
        }
        let filtered: [EduHelper.CourseGrade]
        if searchText.isEmpty {
            filtered = data.value
        } else {
            filtered = data.value.filter { $0.courseName.localizedCaseInsensitiveContains(searchText) }
        }
        filteredGrades = filtered
        let grouped = Dictionary(grouping: filtered) { $0.semester }
        groupedFilteredGrades = grouped.keys.sorted(by: >).map { (semester: $0, grades: grouped[$0] ?? []) }
    }

    private func updateAnalysis() {
        guard let allCourses = gradeData?.value else {
            gradeAnalysis = nil
            return
        }

        let coursesToAnalyze: [EduHelper.CourseGrade]

        if isSelectionMode {
            coursesToAnalyze = allCourses.filter { selectedItems.contains(SelectionItem(course: $0.courseID)) }
        } else {
            coursesToAnalyze = allCourses
        }

        gradeAnalysis = GradeAnalysisData.fromCourseGrades(coursesToAnalyze)
    }

    // MARK: - CSV Export

    func exportGradesAsCSV() {
        guard let csvString = generateCSVString(from: filteredGrades) else {
            errorToast.show(message: "没有可导出的成绩数据")
            return
        }

        guard let csvData = csvString.data(using: .utf8) else {
            errorToast.show(message: "无法将CSV数据编码为UTF-8")
            return
        }

        #if os(iOS)
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileName = "成绩导出-\(Date().formatted(date: .numeric, time: .shortened)).csv"
        let sanitizedFileName = fileName.replacingOccurrences(of: "/", with: "-")
        let fileURL = temporaryDirectory.appendingPathComponent(sanitizedFileName)

        do {
            try csvData.write(to: fileURL)

            shareContent = fileURL
            isShareSheetPresented = true

        } catch {
            errorToast.show(message: "无法保存临时的CSV文件: \(error.localizedDescription)")
        }
        #elseif os(macOS)
        let savePanel = NSSavePanel()
        savePanel.title = "导出成绩表格"
        savePanel.nameFieldStringValue = "成绩导出-\(Date().formatted(date: .numeric, time: .shortened)).csv"
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.canCreateDirectories = true

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }
            do {
                try csvData.write(to: url)
            } catch {
                Task { @MainActor in self.errorToast.show(message: "无法保存CSV文件: \(error.localizedDescription)") }
            }
        }
        #endif
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
