//
//  CourseScheduleEditView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/8/2.
//

import SwiftUI

// MARK: - Content

struct CourseScheduleEditContent: View {
    let schedule: CustomCourseScheduleGRDB
    let isCurrentSchedule: Bool

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
            } footer: {
                Text("点击后该课表将成为当前课表")
            }

            Section {
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
}

// MARK: - 业务容器

struct CourseScheduleEditView: View {
    let schedule: CustomCourseScheduleGRDB

    @Environment(\.dismiss) private var dismiss

    @State private var isCurrentSchedule: Bool = false
    @State private var errorToast: ToastState = .errorTitle

    var body: some View {
        CourseScheduleEditContent(
            schedule: schedule,
            isCurrentSchedule: isCurrentSchedule,
            onActivate: activate,
            onDelete: deleteSchedule
        )
        .onAppear {
            isCurrentSchedule = (MMKVHelper.CourseSchedule.currentScheduleID == schedule.id)
        }
        .onReceive(MMKVHelper.CourseSchedule.$currentScheduleID) { scheduleID in
            isCurrentSchedule = (scheduleID == schedule.id)
        }
        .errorToast($errorToast)
    }

    // MARK: - 切换当前课表

    private func activate() {
        CustomCourseScheduleHelper.activateSchedule(id: schedule.id)
        isCurrentSchedule = true
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
}

#Preview("CourseScheduleEditContent") {
    NavigationStack {
        CourseScheduleEditContent(
            schedule: CustomCourseScheduleGRDB(
                id: "preview-id",
                name: "我的课表 1",
                semesterStartDate: .now,
                weekCount: 20,
                remarks: "",
                createdAt: .now
            ),
            isCurrentSchedule: false,
            onActivate: {},
            onDelete: {}
        )
    }
}
