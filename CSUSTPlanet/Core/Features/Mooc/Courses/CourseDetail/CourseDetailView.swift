//
//  CourseDetailView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/8/23.
//

import CSUSTKit
import Foundation
import SwiftUI

struct CourseDetailView: View {
    let course: MoocHelper.Course

    @State private var assignments: [MoocHelper.Assignment] = []

    @State private var isLoading = false

    @State private var errorToast: ToastState = .errorTitle
    @State private var successToast: ToastState = .successTitle

    @State private var isInitial = true

    // MARK: - Body

    var body: some View {
        CourseDetailContent(
            course: course,
            assignments: assignments,
            isLoading: isLoading,
            errorToast: $errorToast,
            successToast: $successToast,
            onRefreshAssignments: {
                await loadAssignments(course: course)
            },
            onAddAssignmentsToReminders: addAssignmentsToReminders
        )
        .task {
            guard isInitial else {
                return
            }
            isInitial = false
            await loadAssignments(course: course)
        }
    }

    // MARK: - Methods

    private func loadAssignments(course: MoocHelper.Course) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            assignments = try await AuthManager.shared.withAuthRetry(system: .mooc) {
                try await AuthManager.shared.moocHelper.getCourseAssignments(course: course)
            }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func addAssignmentsToReminders(_ alertHourOffset: Int, _ alertMinuteOffset: Int) async {
        guard !assignments.isEmpty else {
            errorToast.show(message: "当前没有可添加的作业")
            return
        }

        do {
            let dateFormatter = makeReminderDateFormatter()
            let calendar = try await CalendarUtil.getOrCreateReminderCalendar(suffix: "作业")

            for assignment in assignments {
                guard assignment.canSubmit else { continue }

                let alarmOffset = TimeInterval(-(alertHourOffset * 3600 + alertMinuteOffset * 60))
                let dueDateWithAlarm = assignment.deadline.addingTimeInterval(alarmOffset)

                try await CalendarUtil.addReminder(
                    calendar: calendar,
                    title: assignment.title,
                    dueDate: dueDateWithAlarm,
                    notes: "截止提交时间：\(dateFormatter.string(from: assignment.deadline))\n课程老师：\(assignment.publisher)"
                )
            }

            successToast.show(message: "添加到提醒事项成功")
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func makeReminderDateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return dateFormatter
    }
}
