//
//  CourseScheduleCourseDetailView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/8/2.
//

import CSUSTKit
import Foundation
import GRDB
import SwiftUI

// MARK: - Content

private struct CourseScheduleCourseDetailContent: View {
    let course: CustomCourseGRDB
    let sessions: [CustomSessionGRDB]

    let onSaveCourseInfo: (String, String?, String?) -> Bool
    let onDeleteCourse: () -> Void

    @State private var isEditingCourseInfo: Bool = false
    @State private var editableName: String = ""
    @State private var editableTeacher: String = ""
    @State private var editableGroupName: String = ""

    @State private var isDeleteConfirmPresented: Bool = false

    var body: some View {
        Form {
            courseInfoSection

            Section("时间安排") {
                if sessions.isEmpty {
                    Text("暂无时间安排")
                        .foregroundStyle(.secondary)
                }
                ForEach(sessions) { session in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(weekdayText(session.dayOfWeek)) · 第 \(session.startSection)-\(session.endSection) 节")
                        Text(sessionSubtitle(session))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }

            Section {
                Button(role: .destructive) {
                    isDeleteConfirmPresented = true
                } label: {
                    Text("删除课程")
                }
            }
        }
        .alert(
            "删除课程",
            isPresented: $isDeleteConfirmPresented,
            presenting: course
        ) { course in
            Button("删除", role: .destructive) {
                onDeleteCourse()
            }
            Button("取消", role: .cancel) {}
        } message: { course in
            Text("确定要删除「\(course.courseName)」吗？删除后不可恢复")
        }
        .formStyle(.grouped)
        .navigationTitle(course.courseName)
    }

    // MARK: - 课程信息

    private var courseInfoSection: some View {
        Section {
            if isEditingCourseInfo {
                LabeledContent("名称") {
                    TextField("输入名称", text: $editableName)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("教师") {
                    TextField("未设置", text: $editableTeacher)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("组名") {
                    TextField("未设置", text: $editableGroupName)
                        .multilineTextAlignment(.trailing)
                }
            } else {
                LabeledContent("名称", value: course.courseName)
                LabeledContent("教师", value: course.teacher?.nilIfEmpty ?? "未设置")
                LabeledContent("组名", value: course.groupName?.nilIfEmpty ?? "未设置")
            }
        } header: {
            HStack {
                Text("课程信息")
                Spacer()
                if isEditingCourseInfo {
                    Button("取消") {
                        withAnimation {
                            isEditingCourseInfo = false
                        }
                    }
                    Button("保存") {
                        saveCourseInfo()
                    }
                } else {
                    Button("编辑") {
                        editableName = course.courseName
                        editableTeacher = course.teacher ?? ""
                        editableGroupName = course.groupName ?? ""
                        withAnimation {
                            isEditingCourseInfo = true
                        }
                    }
                }
            }
        }
    }

    private func saveCourseInfo() {
        if onSaveCourseInfo(editableName, editableTeacher, editableGroupName) {
            withAnimation {
                isEditingCourseInfo = false
            }
        }
    }

    // MARK: - Helpers

    private func weekdayText(_ dayOfWeek: Int) -> String {
        guard let day = EduHelper.DayOfWeek(rawValue: dayOfWeek) else {
            return "未知"
        }
        return "周\(day.stringValue)"
    }

    private func sessionSubtitle(_ session: CustomSessionGRDB) -> String {
        let weeks = session.weeks.values.map(String.init).joined(separator: ",")
        var parts: [String] = []
        if let classroom = session.classroom, !classroom.isEmpty {
            parts.append(classroom)
        }
        parts.append("第 \(weeks) 周")
        return parts.joined(separator: " · ")
    }
}

// MARK: - 业务容器

struct CourseScheduleCourseDetailView: View {
    @State var course: CustomCourseGRDB

    @Environment(\.dismiss) private var dismiss

    @State private var sessions: [CustomSessionGRDB] = []
    @State private var sessionObserver: (any DatabaseCancellable)?
    @State private var isInitial: Bool = true

    @State private var errorToast: ToastState = .errorTitle

    var body: some View {
        CourseScheduleCourseDetailContent(
            course: course,
            sessions: sessions,
            onSaveCourseInfo: saveCourseInfo,
            onDeleteCourse: deleteCourse
        )
        .task {
            guard isInitial else { return }
            isInitial = false
            observeData()
        }
        .errorToast($errorToast)
    }

    // MARK: - 保存课程信息

    private func saveCourseInfo(name: String, teacher: String?, groupName: String?) -> Bool {
        do {
            try CustomCourseScheduleHelper.updateCourse(
                id: course.id,
                name: name,
                teacher: teacher,
                groupName: groupName
            )
            return true
        } catch {
            errorToast.show(message: "保存失败：\(error.localizedDescription)")
            return false
        }
    }

    // MARK: - 删除课程

    private func deleteCourse() {
        do {
            try CustomCourseScheduleHelper.deleteCourse(id: course.id)
            dismiss()
        } catch {
            errorToast.show(message: "删除失败：\(error.localizedDescription)")
        }
    }

    // MARK: - 数据观察

    private func observeData() {
        guard let pool = DatabaseManager.shared.pool else { return }

        let observation = ValueObservation.tracking { db -> (CustomCourseGRDB?, [CustomSessionGRDB]) in
            let fetchedCourse = try CustomCourseGRDB.fetchOne(db, key: course.id)
            let sessions =
                try CustomSessionGRDB
                .filter(CustomSessionGRDB.Columns.courseId == course.id)
                .fetchAll(db)
            return (fetchedCourse, sessions)
        }
        .map { result in
            let sortedSessions = result.1.sorted {
                if $0.dayOfWeek != $1.dayOfWeek {
                    return $0.dayOfWeek < $1.dayOfWeek
                }
                return $0.startSection < $1.startSection
            }
            return (result.0, sortedSessions)
        }

        sessionObserver = observation.start(
            in: pool,
            scheduling: .immediate,
            onError: { _ in },
            onChange: { result in
                Task { @MainActor in
                    if let course = result.0 {
                        self.course = course
                    }
                    sessions = result.1
                }
            }
        )
    }
}

#Preview("CourseScheduleCourseDetailContent") {
    NavigationStack {
        CourseScheduleCourseDetailContent(
            course: CustomCourseGRDB(
                id: "preview-course",
                scheduleId: "preview-schedule",
                courseName: "高等数学",
                teacher: "刘文正",
                groupName: "08"
            ),
            sessions: [
                CustomSessionGRDB(
                    id: "1",
                    courseId: "preview-course",
                    dayOfWeek: 1,
                    startSection: 5,
                    endSection: 6,
                    classroom: "金13-106",
                    weeks: JSONIntArray([1, 2, 3, 4, 5, 6, 7, 8])
                ),
                CustomSessionGRDB(
                    id: "2",
                    courseId: "preview-course",
                    dayOfWeek: 3,
                    startSection: 1,
                    endSection: 2,
                    classroom: nil,
                    weeks: JSONIntArray([1, 2, 3, 4, 5, 6, 7, 8])
                ),
            ],
            onSaveCourseInfo: { _, _, _ in true },
            onDeleteCourse: {}
        )
    }
}
