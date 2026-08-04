//
//  CourseScheduleCourseFormSheet.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/8/2.
//

import Foundation
import SwiftUI

// MARK: - Content

private struct CourseScheduleCourseFormContent: View {
    let onSubmit: (String, String?, String?) -> Bool

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var teacher: String = ""
    @State private var groupName: String = ""

    var body: some View {
        Form {
            Section("课程信息") {
                LabeledContent("名称") {
                    TextField("必填", text: $name)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("教师") {
                    TextField("未设置", text: $teacher)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("组名") {
                    TextField("未设置", text: $groupName)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("添加课程")
        .inlineToolbarTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("添加") {
                    submit()
                }
            }
        }
    }

    // MARK: - Methods

    private func submit() {
        if onSubmit(name, teacher, groupName) {
            dismiss()
        }
    }
}

// MARK: - 业务容器

struct CourseScheduleCourseFormSheet: View {
    let scheduleID: String

    @State private var errorToast: ToastState = .errorTitle

    var body: some View {
        NavigationStack {
            CourseScheduleCourseFormContent(
                onSubmit: submit
            )
        }
        .errorToast($errorToast)
    }

    // MARK: - 新增课程

    private func submit(name: String, teacher: String?, groupName: String?) -> Bool {
        do {
            try CustomCourseScheduleHelper.insertCourse(
                scheduleId: scheduleID,
                name: name,
                teacher: teacher,
                groupName: groupName
            )
            return true
        } catch {
            errorToast.show(message: "添加失败：\(error.localizedDescription)")
            return false
        }
    }
}

#Preview("CourseScheduleCourseFormContent") {
    CourseScheduleCourseFormContent(
        onSubmit: { _, _, _ in true }
    )
}
