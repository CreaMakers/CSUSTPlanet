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
        }
        .formStyle(.grouped)
        .navigationTitle(schedule.name)
    }
}

// MARK: - 业务容器

struct CourseScheduleEditView: View {
    let schedule: CustomCourseScheduleGRDB

    @State private var isCurrentSchedule: Bool = false
    @State private var successToast: ToastState = .successTitle

    var body: some View {
        CourseScheduleEditContent(
            schedule: schedule,
            isCurrentSchedule: isCurrentSchedule,
            onActivate: activate
        )
        .onAppear {
            isCurrentSchedule = (MMKVHelper.CourseSchedule.currentScheduleID == schedule.id)
        }
        .onReceive(MMKVHelper.CourseSchedule.$currentScheduleID) { scheduleID in
            isCurrentSchedule = (scheduleID == schedule.id)
        }
        .successToast($successToast)
    }

    // MARK: - 切换当前课表

    private func activate() {
        MMKVHelper.CourseSchedule.currentScheduleID = schedule.id
        isCurrentSchedule = true
        successToast.show(message: "已激活「\(schedule.name)」")
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
            onActivate: {}
        )
    }
}
