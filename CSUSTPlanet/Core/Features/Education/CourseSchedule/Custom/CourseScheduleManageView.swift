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

    @State private var isDeleteConfirmPresented: Bool = false

    var body: some View {
        Form {
            Section("课表信息") {
                LabeledContent("名称", value: schedule.name)
                LabeledContent("开学日期", value: CourseScheduleUtil.dateFormatter.string(from: schedule.semesterStartDate))
                LabeledContent("总周数", value: "\(schedule.weekCount) 周")
            }

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
        .formStyle(.grouped)
        .navigationTitle(schedule.name)
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
    let schedule: CustomCourseScheduleGRDB

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
            onDelete: deleteSchedule
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
            observeCourseItems()
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

    // MARK: - 课程列表观察

    private func observeCourseItems() {
        guard let pool = DatabaseManager.shared.pool else { return }

        let observation = ValueObservation.tracking { db -> [CourseScheduleCourseItem] in
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
            return
                courses
                .map { CourseScheduleCourseItem(course: $0, sessionCount: sessionCounts[$0.id] ?? 0) }
                .sorted { $0.course.courseName.localizedStandardCompare($1.course.courseName) == .orderedAscending }
        }

        courseObserver = observation.start(
            in: pool,
            scheduling: .immediate,
            onError: { _ in },
            onChange: { items in
                Task { @MainActor in
                    courseItems = items
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
            onDelete: {}
        )
    }
}
