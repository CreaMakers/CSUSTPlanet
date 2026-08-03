//
//  CourseScheduleManageView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/8/2.
//

import Combine
import Foundation
import GRDB
import SwiftUI

/// 课程列表项：课程及其时间安排数量
private struct CourseScheduleCourseItem: Identifiable {
    let course: CustomCourseGRDB
    let sessionCount: Int

    var id: String { course.id }
}

// MARK: - Content

private struct CourseScheduleManageContent: View {
    let schedule: CustomCourseScheduleGRDB
    let isCurrentSchedule: Bool
    let courseItems: [CourseScheduleCourseItem]

    let onActivate: () -> Void
    let onDelete: () -> Void
    let onDeleteCourse: (CustomCourseGRDB) -> Void
    let onSaveScheduleInfo: (String, Date, Int, String) -> Bool

    @State private var isDeleteConfirmPresented: Bool = false
    @State private var coursePendingDelete: CustomCourseGRDB?

    @State private var isEditingScheduleInfo: Bool = false
    @State private var editableName: String = ""
    @State private var editableStartDate: Date = .now
    @State private var editableWeekCount: Int = 20
    @State private var editableRemarks: String = ""

    var body: some View {
        Form {
            scheduleInfoSection

            Section {
                if courseItems.isEmpty {
                    Text("暂无课程")
                        .foregroundStyle(.secondary)
                }
                ForEach(courseItems) { item in
                    NavigationLink(value: AppRoute.features(.education(.courseSchedule(.courseDetail(item.course))))) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.course.courseName)
                            Text(courseSubtitle(for: item))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            coursePendingDelete = item.course
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
            } header: {
                Text("课程列表 (\(courseItems.count))")
            }

            Section {
                Button {
                    onActivate()
                } label: {
                    HStack {
                        Text(isCurrentSchedule ? "当前课表" : "设为当前课表")
                        if isCurrentSchedule {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .disabled(isCurrentSchedule)
                Button(role: .destructive) {
                    isDeleteConfirmPresented = true
                } label: {
                    Text("删除课表")
                }
            }
        }
        .alert(
            "删除课表",
            isPresented: $isDeleteConfirmPresented,
            presenting: schedule
        ) { schedule in
            Button("删除", role: .destructive) {
                onDelete()
            }
            Button("取消", role: .cancel) {}
        } message: { schedule in
            Text("确定要删除「\(schedule.name)」吗？删除后不可恢复")
        }
        .alert(
            "删除课程",
            isPresented: Binding(get: { coursePendingDelete != nil }, set: { if !$0 { coursePendingDelete = nil } }),
            presenting: coursePendingDelete
        ) { course in
            Button("删除", role: .destructive) {
                onDeleteCourse(course)
            }
            Button("取消", role: .cancel) {}
        } message: { course in
            Text("确定要删除「\(course.courseName)」吗？删除后不可恢复")
        }
        .formStyle(.grouped)
        .navigationTitle(schedule.name)
    }

    // MARK: - 课表信息

    private var scheduleInfoSection: some View {
        Section {
            if isEditingScheduleInfo {
                LabeledContent("名称") {
                    TextField("输入名称", text: $editableName)
                        .multilineTextAlignment(.trailing)
                }
                DatePicker("开学日期", selection: $editableStartDate, displayedComponents: .date)
                Stepper("总周数：\(editableWeekCount) 周", value: $editableWeekCount, in: 1...40)
                VStack(alignment: .leading, spacing: 4) {
                    Text("备注")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $editableRemarks)
                        .frame(minHeight: 80)
                }
            } else {
                LabeledContent("名称", value: schedule.name)
                LabeledContent("开学日期", value: CourseScheduleUtil.dateFormatter.string(from: schedule.semesterStartDate))
                LabeledContent("总周数", value: "\(schedule.weekCount) 周")
                VStack(alignment: .leading, spacing: 4) {
                    Text("备注")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(schedule.remarks.isEmpty ? "暂无备注" : schedule.remarks)
                }
                .padding(.vertical, 2)
            }
        } header: {
            HStack {
                Text("课表信息")
                Spacer()
                if isEditingScheduleInfo {
                    Button("取消") {
                        withAnimation {
                            isEditingScheduleInfo = false
                        }
                    }
                    Button("保存") {
                        saveScheduleInfo()
                    }
                } else {
                    Button("编辑") {
                        editableName = schedule.name
                        editableStartDate = schedule.semesterStartDate
                        editableWeekCount = schedule.weekCount
                        editableRemarks = schedule.remarks
                        withAnimation {
                            isEditingScheduleInfo = true
                        }
                    }
                }
            }
        }
    }

    private func saveScheduleInfo() {
        if onSaveScheduleInfo(editableName, editableStartDate, editableWeekCount, editableRemarks) {
            withAnimation {
                isEditingScheduleInfo = false
            }
        }
    }

    // MARK: - Helpers

    private func courseSubtitle(for item: CourseScheduleCourseItem) -> String {
        var parts: [String] = []
        if let teacher = item.course.teacher, !teacher.isEmpty {
            parts.append(teacher)
        }
        if let groupName = item.course.groupName, !groupName.isEmpty {
            parts.append(groupName)
        }
        parts.append("\(item.sessionCount) 个时间安排")
        return parts.joined(separator: " · ")
    }
}

// MARK: - 业务容器

struct CourseScheduleManageView: View {
    @State var schedule: CustomCourseScheduleGRDB

    @Environment(\.dismiss) private var dismiss

    @State private var isCurrentSchedule: Bool = false
    @State private var errorToast: ToastState = .errorTitle

    @State private var courseItems: [CourseScheduleCourseItem] = []
    @State private var courseObserver: (any DatabaseCancellable)?
    @State private var isInitial: Bool = true

    var body: some View {
        CourseScheduleManageContent(
            schedule: schedule,
            isCurrentSchedule: isCurrentSchedule,
            courseItems: courseItems,
            onActivate: activate,
            onDelete: deleteSchedule,
            onDeleteCourse: deleteCourse,
            onSaveScheduleInfo: saveScheduleInfo
        )
        .onReceive(MMKVHelper.CourseSchedule.$currentScheduleID) { scheduleID in
            withAnimation {
                isCurrentSchedule = (scheduleID == schedule.id)
            }
        }
        .task {
            guard isInitial else { return }
            isInitial = false
            isCurrentSchedule = (MMKVHelper.CourseSchedule.currentScheduleID == schedule.id)
            observeData()
        }
        .errorToast($errorToast)
    }

    // MARK: - 切换当前课表

    private func activate() {
        CustomCourseScheduleHelper.activateSchedule(id: schedule.id)
    }

    // MARK: - 删除课表

    private func deleteSchedule() {
        do {
            try CustomCourseScheduleHelper.deleteSchedule(id: schedule.id)
            dismiss()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    // MARK: - 保存课表信息

    private func saveScheduleInfo(name: String, semesterStartDate: Date, weekCount: Int, remarks: String) -> Bool {
        do {
            try CustomCourseScheduleHelper.updateSchedule(
                id: schedule.id,
                name: name,
                semesterStartDate: semesterStartDate,
                weekCount: weekCount,
                remarks: remarks
            )
            return true
        } catch {
            errorToast.show(message: "保存失败：\(error.localizedDescription)")
            return false
        }
    }

    // MARK: - 删除课程

    private func deleteCourse(_ course: CustomCourseGRDB) {
        do {
            try CustomCourseScheduleHelper.deleteCourse(id: course.id)
        } catch {
            errorToast.show(message: "删除失败：\(error.localizedDescription)")
        }
    }

    // MARK: - 数据观察

    private func observeData() {
        guard let pool = DatabaseManager.shared.pool else { return }

        let observation = ValueObservation.tracking { db -> (CustomCourseScheduleGRDB?, [CourseScheduleCourseItem]) in
            let fetchedSchedule = try CustomCourseScheduleGRDB.fetchOne(db, key: schedule.id)
            let courses =
                try CustomCourseGRDB
                .filter(CustomCourseGRDB.Columns.scheduleId == schedule.id)
                .fetchAll(db)
            let courseIDs = courses.map(\.id)
            let sessions =
                try CustomSessionGRDB
                .filter(courseIDs.contains(CustomSessionGRDB.Columns.courseId))
                .fetchAll(db)
            let sessionCounts = Dictionary(grouping: sessions, by: \.courseId).mapValues(\.count)
            let items =
                courses
                .map { CourseScheduleCourseItem(course: $0, sessionCount: sessionCounts[$0.id] ?? 0) }
                .sorted { $0.course.courseName.localizedStandardCompare($1.course.courseName) == .orderedAscending }
            return (fetchedSchedule, items)
        }

        courseObserver = observation.start(
            in: pool,
            scheduling: .immediate,
            onError: { _ in },
            onChange: { result in
                Task { @MainActor in
                    withAnimation {
                        if let schedule = result.0 {
                            self.schedule = schedule
                        }
                        courseItems = result.1
                    }
                }
            }
        )
    }
}

#Preview("CourseScheduleManageContent") {
    NavigationStack {
        CourseScheduleManageContent(
            schedule: CustomCourseScheduleGRDB(
                id: "preview-id",
                name: "我的课表 1",
                semesterStartDate: .now,
                weekCount: 20,
                remarks: "",
                createdAt: .now
            ),
            isCurrentSchedule: false,
            courseItems: [],
            onActivate: {},
            onDelete: {},
            onDeleteCourse: { _ in },
            onSaveScheduleInfo: { _, _, _, _ in true }
        )
    }
}
