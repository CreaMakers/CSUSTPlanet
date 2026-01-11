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
import WidgetKit

@MainActor
class GradeQueryViewModel: ObservableObject {
    struct SelectionItem: Hashable {
        let course: String
    }

    // MARK: States

    @Published var data: Cached<[EduHelper.CourseGrade]>? = nil {
        didSet { updateAnalysis() }
    }
    @Published var analysis: GradeAnalysisData? = nil
    @Published var searchText: String = ""
    @Published var errorMessage: String = ""
    @Published var warningMessage: String = ""

    @Published var isLoading: Bool = false
    @Published var isShowingShareSheet: Bool = false
    @Published var isShowingError: Bool = false
    @Published var isShowingWarning: Bool = false

    @Published var isSelectionMode: Bool = false {
        didSet { updateAnalysis() }
    }

    @Published var selectedItems = Set<SelectionItem>() {
        didSet { if isSelectionMode { updateAnalysis() } }
    }

    @Published var expandedSemesters: Set<String> = []

    @Published var semesterGPAs: [String: Double] = [:]

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

    var groupedFilteredCourseGrades: [(semester: String, grades: [EduHelper.CourseGrade])] {
        let grades = filteredCourseGrades
        let grouped = Dictionary(grouping: grades) { $0.semester }
        let sortedSemesters = grouped.keys.sorted(by: >)
        return sortedSemesters.map { (semester: $0, grades: grouped[$0] ?? []) }
    }

    // MARK: - Methods

    init() {
        guard let data = MMKVHelper.shared.courseGradesCache else { return }
        self.data = data
        self.expandedSemesters = Set(data.value.map { $0.semester })
    }

    func task() {
        guard !isLoaded else { return }
        isLoaded = true
        loadCourseGrades()
    }

    func loadCourseGrades() {
        isLoading = true
        Task {
            defer {
                isLoading = false
            }
            if let eduHelper = AuthManager.shared.eduHelper {
                do {
                    let courseGrades = try await eduHelper.courseService.getCourseGrades(academicYearSemester: nil, courseNature: nil, courseName: "")
                    let data = Cached(cachedAt: .now, value: courseGrades)
                    self.data = data
                    self.expandedSemesters = Set(courseGrades.map { $0.semester })
                    self.semesterGPAs = Dictionary(grouping: courseGrades, by: { $0.semester }).map { semester, grades in
                        let totalCredits = grades.reduce(0) { $0 + $1.credit }
                        let totalGradePoints = grades.reduce(0) { $0 + $1.gradePoint * $1.credit }
                        let gpa = totalCredits > 0 ? totalGradePoints / totalCredits : 0.0
                        return (semester: semester, gpa: gpa)
                    }
                    .reduce(into: [:]) { $0[$1.semester] = $1.gpa }
                    MMKVHelper.shared.courseGradesCache = data
                    MMKVHelper.shared.sync()
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
                self.expandedSemesters = Set(data.value.map { $0.semester })
                self.semesterGPAs = Dictionary(grouping: data.value, by: { $0.semester }).map { semester, grades in
                    let totalCredits = grades.reduce(0) { $0 + $1.credit }
                    let totalGradePoints = grades.reduce(0) { $0 + $1.gradePoint * $1.credit }
                    let gpa = totalCredits > 0 ? totalGradePoints / totalCredits : 0.0
                    return (semester: semester, gpa: gpa)
                }
                .reduce(into: [:]) { $0[$1.semester] = $1.gpa }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.warningMessage = String(format: "教务系统未登录，\n已加载上次查询数据（%@）", DateUtil.relativeTimeString(for: data.cachedAt))
                    self.isShowingWarning = true
                }
            }
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

    func bindingForSemester(_ semester: String) -> Binding<Bool> {
        Binding<Bool>(
            get: { [weak self] in
                self?.expandedSemesters.contains(semester) ?? false
            },
            set: { [weak self] newValue in
                if newValue {
                    self?.expandedSemesters.insert(semester)
                } else {
                    self?.expandedSemesters.remove(semester)
                }
            }
        )
    }

    // MARK: - Selection Mode

    func enterSelectionMode() {
        selectedItems = Set(filteredCourseGrades.map { SelectionItem(course: $0.courseID) })
        isSelectionMode = true
    }

    func exitSelectionMode() {
        isSelectionMode = false
        selectedItems.removeAll()
    }

    func selectAll() {
        selectedItems = Set(filteredCourseGrades.map { SelectionItem(course: $0.courseID) })
    }

    func selectNone() {
        selectedItems.removeAll()
    }

    private func updateAnalysis() {
        guard let allCourses = data?.value else {
            analysis = nil
            return
        }

        let coursesToAnalyze: [EduHelper.CourseGrade]

        if isSelectionMode {
            coursesToAnalyze = allCourses.filter { selectedItems.contains(SelectionItem(course: $0.courseID)) }
        } else {
            coursesToAnalyze = allCourses
        }

        analysis = GradeAnalysisData.fromCourseGrades(coursesToAnalyze)
    }

    // MARK: - CSV Export

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
