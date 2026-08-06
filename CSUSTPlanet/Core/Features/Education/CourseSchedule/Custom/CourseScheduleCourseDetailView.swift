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

// MARK: - 单个时间安排 Section

private struct CourseScheduleSessionSection: View {
    let session: CustomSessionGRDB
    let weekCount: Int

    let onSave: (CustomSessionGRDB, Int, Int, Int, String?, JSONIntArray) -> Bool
    let onDelete: (CustomSessionGRDB) -> Void

    @State private var isExpanded: Bool = false
    @State private var isEditing: Bool = false

    @State private var editingDayOfWeek: Int = 1
    @State private var editingStartSection: Int = 1
    @State private var editingEndSection: Int = 2
    @State private var editingClassroom: String = ""
    @State private var editingWeeks: [Int] = []

    @State private var isWeeksSheetPresented: Bool = false
    @State private var isDeleteConfirmPresented: Bool = false

    var body: some View {
        Section {
            DisclosureGroup(isExpanded: $isExpanded) {
                if isEditing {
                    Picker("星期", selection: $editingDayOfWeek) {
                        ForEach(0..<7, id: \.self) { day in
                            Text(weekdayText(day)).tag(day)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("开始节次", selection: $editingStartSection) {
                        ForEach(1...10, id: \.self) { section in
                            Text("第 \(section) 节").tag(section)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("结束节次", selection: $editingEndSection) {
                        ForEach(1...10, id: \.self) { section in
                            Text("第 \(section) 节").tag(section)
                        }
                    }
                    .pickerStyle(.menu)

                    LabeledContent("教室") {
                        TextField("未设置", text: $editingClassroom)
                            .multilineTextAlignment(.trailing)
                    }

                    LabeledContent("周次") {
                        Text("已选 \(editingWeeks.count) 周")
                            .foregroundStyle(.tint)
                    }
                    .contentShape(.rect)
                    .onTapGesture {
                        isWeeksSheetPresented = true
                    }
                } else {
                    LabeledContent("星期", value: weekdayText(session.dayOfWeek))
                    LabeledContent("节次", value: "第 \(session.startSection)-\(session.endSection) 节")
                    LabeledContent("教室", value: session.classroom?.nilIfEmpty ?? "未设置")
                    LabeledContent("周次", value: weeksText(session.weeks))
                }
            } label: {
                summaryLabel
            }
        } header: {
            HStack {
                Spacer()
                if isEditing {
                    Button("取消") {
                        withAnimation {
                            isEditing = false
                        }
                    }
                    Button("保存") {
                        save()
                    }
                } else {
                    Button("编辑") {
                        beginEditing()
                    }
                    Button("删除") {
                        isDeleteConfirmPresented = true
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .alert(
            "删除时间安排",
            isPresented: $isDeleteConfirmPresented
        ) {
            Button("删除", role: .destructive) {
                onDelete(session)
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要删除这个时间安排吗？删除后不可恢复")
        }
        .sheet(isPresented: $isWeeksSheetPresented) {
            CourseScheduleWeeksSelectionSheet(selectedWeeks: $editingWeeks, weekCount: weekCount)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - 摘要

    private var summaryLabel: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(weekdayText(session.dayOfWeek)) · 第 \(session.startSection)-\(session.endSection) 节")
            Text(sessionSubtitle(session))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    // MARK: - 编辑

    private func beginEditing() {
        editingDayOfWeek = session.dayOfWeek
        editingStartSection = session.startSection
        editingEndSection = session.endSection
        editingClassroom = session.classroom ?? ""
        editingWeeks = session.weeks.values
        withAnimation {
            isEditing = true
            isExpanded = true
        }
    }

    private func save() {
        if onSave(session, editingDayOfWeek, editingStartSection, editingEndSection, editingClassroom, JSONIntArray(editingWeeks)) {
            withAnimation {
                isEditing = false
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
        var parts: [String] = []
        if let classroom = session.classroom, !classroom.isEmpty {
            parts.append(classroom)
        }
        parts.append(session.weeks.values.isEmpty ? "未设置周次" : "共 \(session.weeks.values.count) 周")
        return parts.joined(separator: " · ")
    }

    private func weeksText(_ weeks: JSONIntArray) -> String {
        guard !weeks.values.isEmpty else {
            return "未设置"
        }
        return "第 \(weeks.values.map(String.init).joined(separator: ", ")) 周"
    }
}

// MARK: - Content

private struct CourseScheduleCourseDetailContent: View {
    let course: CustomCourseGRDB
    let sessions: [CustomSessionGRDB]
    let weekCount: Int

    let onSaveCourseInfo: (String, String?, String?) -> Bool
    let onDeleteCourse: () -> Void
    let onSaveSession: (CustomSessionGRDB, Int, Int, Int, String?, JSONIntArray) -> Bool
    let onDeleteSession: (CustomSessionGRDB) -> Void

    @State private var isEditingCourseInfo: Bool = false
    @State private var editableName: String = ""
    @State private var editableTeacher: String = ""
    @State private var editableGroupName: String = ""

    @State private var isDeleteConfirmPresented: Bool = false
    @State private var isSessionFormPresented: Bool = false

    var body: some View {
        Form {
            courseInfoSection

            sessionsSection

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
        .sheet(isPresented: $isSessionFormPresented) {
            CourseScheduleSessionFormSheet(courseID: course.id, weekCount: weekCount)
                .presentationDetents([.medium, .large])
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isSessionFormPresented = true
                } label: {
                    Label("添加时间安排", systemImage: "plus")
                }
            }
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

    // MARK: - 时间安排

    private var sessionsSection: some View {
        Group {
            if sessions.isEmpty {
                Section {
                    Text("暂无时间安排")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("时间安排")
                }
            } else {
                ForEach(sessions) { session in
                    CourseScheduleSessionSection(
                        session: session,
                        weekCount: weekCount,
                        onSave: onSaveSession,
                        onDelete: onDeleteSession
                    )
                }
            }
        }
    }
}

// MARK: - 业务容器

struct CourseScheduleCourseDetailView: View {
    @State var course: CustomCourseGRDB

    @Environment(\.dismiss) private var dismiss

    @State private var sessions: [CustomSessionGRDB] = []
    @State private var weekCount: Int = CourseScheduleUtil.weekCount
    @State private var sessionObserver: (any DatabaseCancellable)?
    @State private var isInitial: Bool = true

    @State private var errorToast: ToastState = .errorTitle

    var body: some View {
        CourseScheduleCourseDetailContent(
            course: course,
            sessions: sessions,
            weekCount: weekCount,
            onSaveCourseInfo: saveCourseInfo,
            onDeleteCourse: deleteCourse,
            onSaveSession: saveSession,
            onDeleteSession: deleteSession
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

    // MARK: - 保存时间安排

    private func saveSession(_ session: CustomSessionGRDB, dayOfWeek: Int, startSection: Int, endSection: Int, classroom: String?, weeks: JSONIntArray) -> Bool {
        do {
            try CustomCourseScheduleHelper.updateSession(
                id: session.id,
                dayOfWeek: dayOfWeek,
                startSection: startSection,
                endSection: endSection,
                classroom: classroom,
                weeks: weeks
            )
            return true
        } catch {
            errorToast.show(message: "保存失败：\(error.localizedDescription)")
            return false
        }
    }

    // MARK: - 删除时间安排

    private func deleteSession(_ session: CustomSessionGRDB) {
        do {
            try CustomCourseScheduleHelper.deleteSession(id: session.id)
        } catch {
            errorToast.show(message: "删除失败：\(error.localizedDescription)")
        }
    }

    // MARK: - 数据观察

    private func observeData() {
        guard let pool = DatabaseManager.shared.pool else { return }

        let observation = ValueObservation.tracking { db -> (CustomCourseGRDB?, Int, [CustomSessionGRDB]) in
            let fetchedCourse = try CustomCourseGRDB.fetchOne(db, key: course.id)
            let weekCount = (try CustomCourseScheduleGRDB.fetchOne(db, key: course.scheduleId))?.weekCount ?? CourseScheduleUtil.weekCount
            let sessions =
                try CustomSessionGRDB
                .filter(CustomSessionGRDB.Columns.courseId == course.id)
                .fetchAll(db)
            return (fetchedCourse, weekCount, sessions)
        }
        .map { result in
            let sortedSessions = result.2.sorted {
                if $0.dayOfWeek != $1.dayOfWeek {
                    return $0.dayOfWeek < $1.dayOfWeek
                }
                return $0.startSection < $1.startSection
            }
            return (result.0, result.1, sortedSessions)
        }

        sessionObserver = observation.start(
            in: pool,
            scheduling: .immediate,
            onError: { _ in },
            onChange: { result in
                Task { @MainActor in
                    withAnimation {
                        if let course = result.0 {
                            self.course = course
                        }
                        weekCount = result.1
                        sessions = result.2
                    }
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
            weekCount: 20,
            onSaveCourseInfo: { _, _, _ in true },
            onDeleteCourse: {},
            onSaveSession: { _, _, _, _, _, _ in true },
            onDeleteSession: { _ in }
        )
    }
}
