//
//  CourseScheduleCreateSheet.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/8/2.
//

import CSUSTKit
import Foundation
import SwiftUI

// MARK: - Content

struct CourseScheduleCreateContent: View {
    let isImportFromSchool: Bool
    @State var name: String
    let defaultStartDate: Date?

    let onSubmit: (String, Date) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var semesterStartDate: Date = .now

    var body: some View {
        Form {
            Section("课表名称") {
                TextField("课表名称", text: $name)
            }

            if !isImportFromSchool {
                Section {
                    DatePicker("开学日期", selection: $semesterStartDate, displayedComponents: .date)
                } header: {
                    Text("开学日期")
                } footer: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("必须选择周日作为开学日期")
                        Text("用于计算当前周次，可在后续编辑功能中修改")
                    }
                }
            } else {
                Section {
                    LabeledContent("开学日期", value: CourseScheduleUtil.dateFormatter.string(from: defaultStartDate ?? .now))
                } footer: {
                    Text("开学日期取自学校课表")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(isImportFromSchool ? "从学校课表导入" : "从空白创建")
        .inlineToolbarTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("创建") {
                    onSubmit(name, semesterStartDate)
                }
            }
        }
    }
}

// MARK: - 业务容器

struct CourseScheduleCreateSheet: View {
    let isImportFromSchool: Bool
    let defaultName: String
    let defaultStartDate: Date?

    @Environment(\.dismiss) private var dismiss

    @State private var errorToast: ToastState = .errorTitle

    var body: some View {
        NavigationStack {
            CourseScheduleCreateContent(
                isImportFromSchool: isImportFromSchool,
                name: defaultName,
                defaultStartDate: defaultStartDate,
                onSubmit: submit
            )
        }
        .errorToast($errorToast)
    }

    // MARK: - 创建课表

    private func submit(name: String, semesterStartDate: Date) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.isEmpty ? defaultName : trimmedName

        if isImportFromSchool {
            importFromSchool(name: finalName)
        } else {
            createEmptySchedule(name: finalName, semesterStartDate: semesterStartDate)
        }
    }

    /// 从空白创建
    private func createEmptySchedule(name: String, semesterStartDate: Date) {
        guard CourseScheduleUtil.getDayOfWeek(semesterStartDate) == .sunday else {
            errorToast.show(message: "开学日期必须是周日")
            return
        }
        guard let pool = DatabaseManager.shared.pool else {
            errorToast.show(message: DatabaseManagerError.databaseUnavailable.localizedDescription)
            return
        }

        do {
            var schedule = CustomCourseScheduleGRDB(
                id: UUID().uuidString,
                name: name,
                semesterStartDate: semesterStartDate,
                weekCount: CourseScheduleUtil.weekCount,
                remarks: "",
                createdAt: .now
            )
            try pool.write { db in
                try schedule.insert(db)
            }
            dismiss()
        } catch {
            errorToast.show(message: "创建失败：\(error.localizedDescription)")
        }
    }

    /// 从学校课表导入
    private func importFromSchool(name: String) {
        guard let schoolCache = MMKVHelper.CourseSchedule.cache else {
            errorToast.show(message: "暂无学校课表数据，请先在「我的课表」页面刷新")
            return
        }
        guard let pool = DatabaseManager.shared.pool else {
            errorToast.show(message: DatabaseManagerError.databaseUnavailable.localizedDescription)
            return
        }

        let data = schoolCache.value
        let scheduleID = UUID().uuidString
        let schedule = CustomCourseScheduleGRDB(
            id: scheduleID,
            name: name,
            semesterStartDate: data.semesterStartDate,
            weekCount: CourseScheduleUtil.resolveWeekCount(data.weekCount),
            remarks: data.remarks.joined(separator: "\n"),
            createdAt: .now
        )

        var courses: [CustomCourseGRDB] = []
        var sessions: [CustomSessionGRDB] = []
        for course in data.courses {
            let courseID = UUID().uuidString
            courses.append(
                CustomCourseGRDB(
                    id: courseID,
                    scheduleId: scheduleID,
                    courseName: course.courseName,
                    teacher: course.teacher,
                    groupName: course.groupName
                )
            )
            for session in course.sessions {
                sessions.append(
                    CustomSessionGRDB(
                        id: UUID().uuidString,
                        courseId: courseID,
                        dayOfWeek: session.dayOfWeek.rawValue,
                        startSection: session.startSection,
                        endSection: session.endSection,
                        classroom: session.classroom,
                        weeks: JSONIntArray(session.weeks)
                    )
                )
            }
        }

        do {
            try pool.write { db in
                var schedule = schedule
                try schedule.insert(db)
                for course in courses {
                    var course = course
                    try course.insert(db)
                }
                for session in sessions {
                    var session = session
                    try session.insert(db)
                }
            }
            dismiss()
        } catch {
            errorToast.show(message: "导入失败：\(error.localizedDescription)")
        }
    }
}

#Preview("CourseScheduleCreateContent") {
    CourseScheduleCreateContent(
        isImportFromSchool: false,
        name: "我的课表 1",
        defaultStartDate: .now,
        onSubmit: { _, _ in }
    )
}

#Preview("CourseScheduleImportContent") {
    CourseScheduleCreateContent(
        isImportFromSchool: true,
        name: "我的课表 1",
        defaultStartDate: .now,
        onSubmit: { _, _ in }
    )
}
