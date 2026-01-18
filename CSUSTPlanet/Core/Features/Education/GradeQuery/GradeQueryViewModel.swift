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
        self.semesterGPAs = Dictionary(grouping: data.value, by: { $0.semester }).map { semester, grades in
            let totalCredits = grades.reduce(0) { $0 + $1.credit }
            let totalGradePoints = grades.reduce(0) { $0 + $1.gradePoint * $1.credit }
            let gpa = totalCredits > 0 ? totalGradePoints / totalCredits : 0.0
            return (semester: semester, gpa: gpa)
        }
        .reduce(into: [:]) { $0[$1.semester] = $1.gpa }
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
                    // let courseGrades = mockCourseGrades
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

// let mockCourseGrades = [
//     EduHelper.CourseGrade(semester: "2024-2025-1", courseID: "04010W0016", courseName: "专业教育与学习方法指导", groupName: "", grade: 93, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420251007953&cj0708id=209036A1C88D4ACD91015464A393DB64&zcj=93", studyMode: "主修", gradeIdentifier: "", credit: 0.5, totalHours: 8, gradePoint: 4.0, retakeSemester: "", assessmentMethod: "考查", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.professionalBasicCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2024-2025-1", courseID: "0403000015", courseName: "体育(一)", groupName: "24交物数校园马拉松男21", grade: 92, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420251009465&cj0708id=88893AD5840E40C4BF33A0001C7D7EA8&zcj=92", studyMode: "主修", gradeIdentifier: "", credit: 1.0, totalHours: 30, gradePoint: 4.0, retakeSemester: "", assessmentMethod: "考查", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.publicCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2024-2025-1", courseID: "0502000040", courseName: "大学英语", groupName: "", grade: 87, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420251007231&cj0708id=8F1A84C0328C4CD0823F637E2A5E87A0&zcj=87", studyMode: "主修", gradeIdentifier: "", credit: 2.5, totalHours: 40, gradePoint: 3.7, retakeSemester: "", assessmentMethod: "考试", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.publicCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2024-2025-1", courseID: "0601000045", courseName: "中国近现代史纲要", groupName: "", grade: 70, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420251007390&cj0708id=A6290163CE0E40849E97BC8B0A97A59A&zcj=70", studyMode: "主修", gradeIdentifier: "", credit: 2.0, totalHours: 32, gradePoint: 2.0, retakeSemester: "", assessmentMethod: "考试", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.publicCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2024-2025-1", courseID: "0601200016", courseName: "中国近现代史纲要课外实践", groupName: "", grade: 88, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420251008819&cj0708id=648CBEC42CFA4315B52BB5930A3F8B90&zcj=88", studyMode: "主修", gradeIdentifier: "", credit: 1.0, totalHours: 1, gradePoint: 3.7, retakeSemester: "", assessmentMethod: "考查", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.professionalPracticalCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2024-2025-1", courseID: "0701000225", courseName: "高等数学A(一)", groupName: "", grade: 82, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420251007957&cj0708id=8779F934B94A4DC082C175617C56F692&zcj=82", studyMode: "主修", gradeIdentifier: "", credit: 5.0, totalHours: 80, gradePoint: 3.3, retakeSemester: "", assessmentMethod: "考试", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.publicCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2024-2025-1", courseID: "0702000005", courseName: "物理学专业导论", groupName: "", grade: 90, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420251007954&cj0708id=DB98A139187E4417BDEFA842CD061FC8&zcj=90", studyMode: "主修", gradeIdentifier: "", credit: 1.0, totalHours: 16, gradePoint: 4.0, retakeSemester: "", assessmentMethod: "考查", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.publicCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2024-2025-1", courseID: "0801000245", courseName: "力学", groupName: "", grade: 83, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420251007956&cj0708id=C5A5C5FE7C654085881DD118DA600F28&zcj=83", studyMode: "主修", gradeIdentifier: "", credit: 4.0, totalHours: 64, gradePoint: 3.3, retakeSemester: "", assessmentMethod: "考试", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.publicCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2024-2025-1", courseID: "0809000052", courseName: "C程序设计基础", groupName: "", grade: 99, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420251007955&cj0708id=ED2E56E2C0B943CFA83A5E23987C2C8F&zcj=99", studyMode: "主修", gradeIdentifier: "", credit: 2.0, totalHours: 32, gradePoint: 4.0, retakeSemester: "", assessmentMethod: "考试", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.publicBasicCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2024-2025-1", courseID: "0809010052", courseName: "C程序设计基础实验", groupName: "", grade: 100, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420251007952&cj0708id=68A2EE1823DD4B0FBA0F2541F1A694BB&zcj=100", studyMode: "主修", gradeIdentifier: "", credit: 0.5, totalHours: 16, gradePoint: 4.0, retakeSemester: "", assessmentMethod: "考查", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.publicBasicCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2024-2025-1", courseID: "1105200015", courseName: "军训", groupName: "", grade: 88, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420251008512&cj0708id=B212C060C9024484B6F0CF9BAE157C7A&zcj=88", studyMode: "主修", gradeIdentifier: "", credit: 2.0, totalHours: 2, gradePoint: 3.7, retakeSemester: "", assessmentMethod: "考查", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.professionalPracticalCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2024-2025-2", courseID: "0302000023", courseName: "思想道德与法治", groupName: "", grade: 76, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420252001995&cj0708id=A7D5EDB6BA5644E9A3BD96673AD5C3D3&zcj=76", studyMode: "主修", gradeIdentifier: "", credit: 2.0, totalHours: 32, gradePoint: 2.7, retakeSemester: "", assessmentMethod: "考试", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.publicCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2024-2025-2", courseID: "0302200015", courseName: "思想道德与法治课外实践", groupName: "", grade: 60, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420252002425&cj0708id=578B126AE756455C8E204C50072F30C9&zcj=60", studyMode: "主修", gradeIdentifier: "", credit: 1.0, totalHours: 1, gradePoint: 1.0, retakeSemester: "", assessmentMethod: "考查", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.professionalPracticalCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2024-2025-2", courseID: "0403000025", courseName: "体育(二)", groupName: "24计通校园马拉松男06", grade: 95, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420252008210&cj0708id=6762C582BB2846778B62DAC7E6746A23&zcj=95", studyMode: "主修", gradeIdentifier: "", credit: 1.0, totalHours: 30, gradePoint: 4.0, retakeSemester: "", assessmentMethod: "考查", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.publicCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2024-2025-2", courseID: "0502000420", courseName: "通用工程英语听说", groupName: "", grade: 75, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420252001340&cj0708id=2E8FAA342C824AB084A8400A30036BB5&zcj=75", studyMode: "主修", gradeIdentifier: "", credit: 2.5, totalHours: 40, gradePoint: 2.7, retakeSemester: "", assessmentMethod: "考试", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.publicCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2024-2025-2", courseID: "0701000219", courseName: "高等数学A（二）", groupName: "", grade: 75, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420252005037&cj0708id=F143EFD4923E454BA304C640F8658FD2&zcj=75", studyMode: "主修", gradeIdentifier: "", credit: 5.0, totalHours: 80, gradePoint: 2.7, retakeSemester: "", assessmentMethod: "考试", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.publicCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2024-2025-2", courseID: "0702000405", courseName: "大学物理B（上）", groupName: "", grade: 66, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420252005217&cj0708id=58E95D74DF9E4E64993BE95F2918D1E4&zcj=66", studyMode: "主修", gradeIdentifier: "", credit: 2.0, totalHours: 32, gradePoint: 1.7, retakeSemester: "", assessmentMethod: "考查", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.publicBasicCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2024-2025-2", courseID: "0800000005", courseName: "工程认知训练", groupName: "", grade: 92, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420252002426&cj0708id=D0B6C9614B6D4FC2842D3932B046DFF0&zcj=92", studyMode: "主修", gradeIdentifier: "", credit: 1.0, totalHours: 1, gradePoint: 4.0, retakeSemester: "", assessmentMethod: "考查", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.professionalPracticalCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2024-2025-2", courseID: "0812000217", courseName: "程序设计、算法与数据结构（一）", groupName: "", grade: 94, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420252009474&cj0708id=2B579EDF0FBE4220B5BBE652E8251D47&zcj=94", studyMode: "主修", gradeIdentifier: "", credit: 3.0, totalHours: 48, gradePoint: 4.0, retakeSemester: "", assessmentMethod: "考试", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.professionalBasicCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2024-2025-2", courseID: "0812000317", courseName: "程序设计、算法与数据结构（一）实验", groupName: "", grade: 86, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420252009475&cj0708id=C3631A59C45E4B8C8E73CC758F5CB5C3&zcj=86", studyMode: "主修", gradeIdentifier: "", credit: 1.5, totalHours: 46, gradePoint: 3.7, retakeSemester: "", assessmentMethod: "考查", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.professionalBasicCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2024-2025-2", courseID: "0812000417", courseName: "程序设计、算法与数据结构（二）", groupName: "", grade: 89, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420252007391&cj0708id=11F39181869D4096A294E75C6DB7B0EE&zcj=89", studyMode: "主修", gradeIdentifier: "", credit: 3.0, totalHours: 48, gradePoint: 3.7, retakeSemester: "", assessmentMethod: "考试", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.professionalCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2024-2025-2", courseID: "0812000519", courseName: "程序设计、算法与数据结构（二）实验", groupName: "", grade: 100, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420252007390&cj0708id=5C5849F215D542CF8C93EEA06EAB051C&zcj=100", studyMode: "主修", gradeIdentifier: "", credit: 1.0, totalHours: 30, gradePoint: 4.0, retakeSemester: "", assessmentMethod: "考查", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.professionalCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2024-2025-2", courseID: "0812001001", courseName: "信息类专业导论", groupName: "", grade: 86, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420252009476&cj0708id=16FDC414778F4D6D8D183BF09719CD8E&zcj=86", studyMode: "主修", gradeIdentifier: "", credit: 1.0, totalHours: 16, gradePoint: 3.7, retakeSemester: "", assessmentMethod: "考查", examNature: "正常考试", courseAttribute: "选修", courseNature: EduHelper.CourseNature.professionalCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2024-2025-2", courseID: "1105000015", courseName: "军事理论", groupName: "", grade: 89, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202420252005676&cj0708id=71EA1E7B4D2D461EB9055DADE33F0186&zcj=89", studyMode: "主修", gradeIdentifier: "", credit: 1.0, totalHours: 16, gradePoint: 3.7, retakeSemester: "", assessmentMethod: "考查", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.publicCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2025-2026-1", courseID: "0403000035", courseName: "体育(三)", groupName: "24计算机跆拳道男11", grade: 73, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202520261006909&cj0708id=3B6D11DF34CA437EA7C2E072F60F4300&zcj=73", studyMode: "主修", gradeIdentifier: "", credit: 1.0, totalHours: 30, gradePoint: 2.3, retakeSemester: "", assessmentMethod: "考查", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.publicCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2025-2026-1", courseID: "0702100025", courseName: "大学物理实验B", groupName: "", grade: 88, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202520261005811&cj0708id=7D22D9FEA7014E978EA22F5BFE1945CA&zcj=88", studyMode: "主修", gradeIdentifier: "", credit: 1.0, totalHours: 30, gradePoint: 3.7, retakeSemester: "", assessmentMethod: "考查", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.publicCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2025-2026-1", courseID: "0812000318", courseName: "程序设计、算法与数据结构（三）", groupName: "", grade: 88, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202520261004669&cj0708id=786B3CC3A2DB4D878B8AFE88BCB0B749&zcj=88", studyMode: "主修", gradeIdentifier: "", credit: 3.0, totalHours: 48, gradePoint: 3.7, retakeSemester: "", assessmentMethod: "考试", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.professionalCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2025-2026-1", courseID: "0812000795", courseName: "软件工程概论", groupName: "", grade: 78, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202520261004672&cj0708id=2A9A395F093C4D7684B60599CD67EEF0&zcj=78", studyMode: "主修", gradeIdentifier: "", credit: 2.5, totalHours: 40, gradePoint: 3.0, retakeSemester: "", assessmentMethod: "考查", examNature: "正常考试", courseAttribute: "选修", courseNature: EduHelper.CourseNature.professionalCourse, courseCategory: ""),
//     EduHelper.CourseGrade(semester: "2025-2026-1", courseID: "0812001737", courseName: "离散结构", groupName: "", grade: 78, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202520261004673&cj0708id=31395E442429425CA1EFFFACB2699D65&zcj=78", studyMode: "主修", gradeIdentifier: "", credit: 3.5, totalHours: 56, gradePoint: 3.0, retakeSemester: "", assessmentMethod: "考试", examNature: "正常考试", courseAttribute: "必修", courseNature: EduHelper.CourseNature.professionalCourse, courseCategory: ""),
//     // EduHelper.CourseGrade(semester: "2025-2026-1", courseID: "X350601001", courseName: "无人机设计与空天科技导论（自然科学）", groupName: "", grade: 97, gradeDetailUrl: "http://xk.csust.edu.cn/jsxsd/kscj/pscj_list.do?xs0101id=202411070108&jx0404id=202520261007343&cj0708id=57E02610653243B987A973F8D5D749EC&zcj=97", studyMode: "主修", gradeIdentifier: "", credit: 2.0, totalHours: 32, gradePoint: 4.0, retakeSemester: "", assessmentMethod: "考查", examNature: "正常考试", courseAttribute: "公选", courseNature: EduHelper.CourseNature.publicElectiveCourse, courseCategory: "自然科学"),
// ]
