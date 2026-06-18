//
//  GradeQueryView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import CSUSTKit
import SwiftUI
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#endif

struct GradeQueryView: View {
    @State private var grades: [EduHelper.CourseGrade]?

    @State private var searchText = ""

    @State private var expandedSemesters: Set<String> = []

    @State private var isSelectionMode = false
    @State private var selectedCourseIDs: Set<String> = []

    @State private var isLoading = false

    @State private var errorToast = ToastState()

    @State private var shareContent: Any?
    @State private var isShareSheetPresented = false

    @State private var isInitial = true

    var body: some View {
        GradeQueryContent(
            grades: grades,
            searchText: $searchText,
            expandedSemesters: $expandedSemesters,
            isSelectionMode: $isSelectionMode,
            selectedCourseIDs: $selectedCourseIDs,
            isLoading: isLoading,
            errorToast: $errorToast,
            shareContent: shareContent,
            isShareSheetPresented: $isShareSheetPresented,
            onRefreshGrades: loadCourseGrades,
            onExportGrades: exportGradesAsCSV
        )
        .onReceive(MMKVHelper.CourseGrades.$cache.dropFirst().receive(on: RunLoop.main)) { data in
            applyData(data)
        }
        .task {
            guard isInitial else {
                return
            }
            isInitial = false
            applyData(MMKVHelper.CourseGrades.cache)
            await loadCourseGrades()
        }
    }

    // MARK: - Methods

    private func loadCourseGrades() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let courseGrades = try await AuthManager.shared.withAuthRetry(system: .edu) {
                try await AuthManager.shared.eduHelper.courseService.getCourseGrades(academicYearSemester: nil, courseNature: nil, courseName: "")
            }
            MMKVHelper.CourseGrades.cache = Cached(cachedAt: .now, value: courseGrades)
            WidgetTimelineRefreshHelper.reloadGradeAnalysis()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func applyData(_ data: Cached<[EduHelper.CourseGrade]>?) {
        grades = data?.value

        guard let data else {
            expandedSemesters = []
            selectedCourseIDs = []
            isSelectionMode = false
            return
        }

        expandedSemesters = Set(data.value.map { $0.semester })
    }

    private func exportGradesAsCSV() {
        guard let grades, let csvString = makeCSVString(from: grades) else {
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
                Task { @MainActor in
                    errorToast.show(message: "无法保存CSV文件: \(error.localizedDescription)")
                }
            }
        }
        #endif
    }

    private func makeCSVString(from courseGrades: [EduHelper.CourseGrade]) -> String? {
        guard !courseGrades.isEmpty else { return nil }

        let header = "开课学期,课程编号,课程名称,分组名,成绩,详细成绩链接,修读方式,成绩标识,学分,总学时,绩点,补重学期,考核方式,考试性质,课程属性,课程性质,课程类别\n"
        let rows = courseGrades.map { grade in
            [
                escapeCSVField(grade.semester),
                escapeCSVField(grade.courseID),
                escapeCSVField(grade.courseName),
                escapeCSVField(grade.groupName),
                "\(grade.grade)",
                escapeCSVField(grade.gradeDetailUrl),
                escapeCSVField(grade.studyMode),
                escapeCSVField(grade.gradeIdentifier),
                "\(grade.credit)",
                "\(grade.totalHours)",
                "\(grade.gradePoint)",
                escapeCSVField(grade.retakeSemester),
                escapeCSVField(grade.assessmentMethod),
                escapeCSVField(grade.examNature),
                escapeCSVField(grade.courseAttribute),
                escapeCSVField(grade.courseNature.rawValue),
                escapeCSVField(grade.courseCategory),
            ].joined(separator: ",")
        }

        return header + rows.joined(separator: "\n")
    }

    private func escapeCSVField(_ field: String) -> String {
        let escapedField = field.replacingOccurrences(of: "\"", with: "\"\"")
        if escapedField.contains(",") || escapedField.contains("\"") {
            return "\"\(escapedField)\""
        }
        return escapedField
    }
}
