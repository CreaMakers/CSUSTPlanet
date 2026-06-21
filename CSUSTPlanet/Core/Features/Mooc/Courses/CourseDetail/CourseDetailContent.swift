//
//  CourseDetailContent.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/21.
//

import CSUSTKit
import SwiftUI

struct CourseDetailContent: View {
    let course: MoocHelper.Course
    let assignments: [MoocHelper.Assignment]

    let isLoading: Bool

    @Binding var errorToast: ToastState
    @Binding var successToast: ToastState

    let onRefreshAssignments: () async -> Void
    let onAddAssignmentsToReminders: (Int, Int) async -> Void

    @State private var isRemindersSettingsPresented = false

    var body: some View {
        CustomScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CourseInfoSection(course: course)
                CourseAssignmentsSection(
                    assignments: assignments,
                    isLoading: isLoading,
                    onRefresh: onRefreshAssignments
                )
            }
            .padding()
        }
        #if os(iOS)
        .background(Color(PlatformColor.systemGroupedBackground))
        #endif
        .errorToast($errorToast)
        .successToast($successToast)
        .sheet(isPresented: $isRemindersSettingsPresented) {
            ReminderOffsetSettingsView { hourOffset, minuteOffset in
                Task {
                    await onAddAssignmentsToReminders(hourOffset, minuteOffset)
                }
            }
        }
        .navigationTitle(course.name)
        .apply { view in
            if let teacher = course.teacher {
                view.navigationSubtitleCompat("\(teacher)老师")
            } else {
                view
            }
        }
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Button(action: { isRemindersSettingsPresented = true }) {
                    Label("添加作业列表到提醒事项", systemImage: "list.bullet.rectangle")
                }
            }
        }
    }
}

#Preview("CourseDetailContent") {
    NavigationStack {
        CourseDetailContent(
            course: MoocCoursesPreviewData.mobileDevelopmentCourse,
            assignments: MoocCoursesPreviewData.assignments,
            isLoading: false,
            errorToast: .constant(.errorTitle),
            successToast: .constant(.successTitle),
            onRefreshAssignments: {},
            onAddAssignmentsToReminders: { _, _ in }
        )
    }
}

#Preview("CourseDetailContent Empty") {
    NavigationStack {
        CourseDetailContent(
            course: MoocCoursesPreviewData.generalEducationCourse,
            assignments: [],
            isLoading: false,
            errorToast: .constant(.errorTitle),
            successToast: .constant(.successTitle),
            onRefreshAssignments: {},
            onAddAssignmentsToReminders: { _, _ in }
        )
    }
}
