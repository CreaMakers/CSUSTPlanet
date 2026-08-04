//
//  CourseScheduleSessionFormSheet.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/8/2.
//

import CSUSTKit
import Foundation
import SwiftUI

// MARK: - Content

private struct CourseScheduleSessionFormContent: View {
    let weekCount: Int

    let onSubmit: (Int, Int, Int, String?, [Int]) -> Bool

    @Environment(\.dismiss) private var dismiss

    @State private var dayOfWeek: Int = 1
    @State private var startSection: Int = 1
    @State private var endSection: Int = 2
    @State private var classroom: String = ""
    @State private var weeks: [Int] = []

    @State private var isWeeksSheetPresented: Bool = false

    var body: some View {
        Form {
            Section {
                Picker("星期", selection: $dayOfWeek) {
                    ForEach(0..<7, id: \.self) { day in
                        Text(weekdayText(day)).tag(day)
                    }
                }
                .pickerStyle(.menu)

                Picker("开始节次", selection: $startSection) {
                    ForEach(1...10, id: \.self) { section in
                        Text("第 \(section) 节").tag(section)
                    }
                }
                .pickerStyle(.menu)

                Picker("结束节次", selection: $endSection) {
                    ForEach(1...10, id: \.self) { section in
                        Text("第 \(section) 节").tag(section)
                    }
                }
                .pickerStyle(.menu)

                LabeledContent("教室") {
                    TextField("未设置", text: $classroom)
                        .multilineTextAlignment(.trailing)
                }

                LabeledContent("周次") {
                    Text(weeks.isEmpty ? "未选择" : "已选 \(weeks.count) 周")
                        .foregroundStyle(.tint)
                }
                .contentShape(.rect)
                .onTapGesture {
                    isWeeksSheetPresented = true
                }
            } footer: {
                Text("周次为空时无法保存")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("添加时间安排")
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
        .sheet(isPresented: $isWeeksSheetPresented) {
            CourseScheduleWeeksSelectionSheet(selectedWeeks: $weeks, weekCount: weekCount)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Methods

    private func submit() {
        if onSubmit(dayOfWeek, startSection, endSection, classroom, weeks) {
            dismiss()
        }
    }

    private func weekdayText(_ dayOfWeek: Int) -> String {
        guard let day = EduHelper.DayOfWeek(rawValue: dayOfWeek) else {
            return "未知"
        }
        return "周\(day.stringValue)"
    }
}

// MARK: - 业务容器

struct CourseScheduleSessionFormSheet: View {
    let courseID: String
    let weekCount: Int

    @State private var errorToast: ToastState = .errorTitle

    var body: some View {
        NavigationStack {
            CourseScheduleSessionFormContent(
                weekCount: weekCount,
                onSubmit: submit
            )
        }
        .errorToast($errorToast)
    }

    // MARK: - 新增时间安排

    private func submit(dayOfWeek: Int, startSection: Int, endSection: Int, classroom: String?, weeks: [Int]) -> Bool {
        do {
            try CustomCourseScheduleHelper.insertSession(
                courseId: courseID,
                dayOfWeek: dayOfWeek,
                startSection: startSection,
                endSection: endSection,
                classroom: classroom,
                weeks: JSONIntArray(weeks)
            )
            return true
        } catch {
            errorToast.show(message: "添加失败：\(error.localizedDescription)")
            return false
        }
    }
}

#Preview("CourseScheduleSessionFormContent") {
    CourseScheduleSessionFormContent(
        weekCount: 20,
        onSubmit: { _, _, _, _, _ in true }
    )
}
