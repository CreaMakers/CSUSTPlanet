//
//  AssignmentsContent.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/20.
//

import CSUSTKit
import SwiftUI

struct AssignmentsContent: View {
    @State private var isNotificationSettingsPresented: Bool = false

    let courseGroups: [TodoAssignmentsData]?

    let isLoading: Bool

    let isNotificationEnabled: Bool
    let notificationOffsetHour: Int
    let notificationOffsetMinute: Int

    @Binding var errorToast: ToastState
    @Binding var isNotificationDeniedAlertPresented: Bool

    let onRefreshAssignments: () async -> Void
    let onSaveNotificationSettings: (Bool, Int, Int) async -> Void
    let onOpenNotificationSettings: () -> Void

    private var submittableAssignmentsCount: Int {
        let referenceDate = Date.now
        return (courseGroups ?? []).reduce(0) { count, group in
            count + group.assignments.filter { $0.isSubmittable(referenceDate: referenceDate) }.count
        }
    }

    var body: some View {
        Group {
            if let courseGroups, !courseGroups.isEmpty {
                CustomScrollView {
                    ForEach(courseGroups, id: \.course.id) { group in
                        AssignmentsCourseSection(group: group)
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView("暂无待提交作业", systemImage: "book.closed", description: Text("当前没有需要提交的作业"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        #if os(iOS)
        .background(Color(PlatformColor.systemGroupedBackground))
        #endif
        .safeRefreshable { await onRefreshAssignments() }
        .errorToast($errorToast)
        .sheet(isPresented: $isNotificationSettingsPresented) {
            AssignmentsNotificationSettings(
                isEnabled: isNotificationEnabled,
                selectedHour: notificationOffsetHour,
                selectedMinute: notificationOffsetMinute,
                onSave: onSaveNotificationSettings
            )
            .presentationDetents([.medium, .large])
        }
        .alert("通知权限被拒绝", isPresented: $isNotificationDeniedAlertPresented) {
            Button(action: { isNotificationDeniedAlertPresented = false }) {
                Text("取消")
            }
            Button(action: onOpenNotificationSettings) {
                Text("前往设置")
            }
        } message: {
            Text("需要开启通知权限以接收待提交作业提醒，请前往系统设置开启通知权限")
        }
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Button(action: { isNotificationSettingsPresented = true }) {
                    Label("作业提醒设置", systemImage: "bell.badge")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(asyncAction: onRefreshAssignments) {
                    if isLoading {
                        ProgressView().smallControlSizeOnMac()
                    } else {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(isLoading)
            }
        }
        .navigationTitle("待提交作业")
        .navigationSubtitleCompat("共\(submittableAssignmentsCount)个可提交作业")
    }
}

enum TodoAssignmentsPreviewData {
    static let referenceDate = Date.now

    static let mobileDevelopmentCourse = MoocHelper.Course(
        id: "10001",
        name: "移动应用开发",
        number: "CS101",
        department: "计算机与通信工程学院",
        teacher: "张老师"
    )

    static let softwareEngineeringCourse = MoocHelper.Course(
        id: "10002",
        name: "软件工程实践",
        number: "CS202",
        department: "计算机与通信工程学院",
        teacher: "李老师"
    )

    static let unsubmittedAssignment = makeAssignment(
        id: 1,
        title: "SwiftUI 列表与状态管理实验报告",
        publisher: "张老师",
        canSubmit: true,
        submitStatus: false,
        deadlineOffset: 2 * 24 * 60 * 60,
        startOffset: -3 * 24 * 60 * 60
    )

    static let submittedAssignment = makeAssignment(
        id: 2,
        title: "课程页面阅读记录",
        publisher: "张老师",
        canSubmit: true,
        submitStatus: true,
        deadlineOffset: 5 * 24 * 60 * 60,
        startOffset: -24 * 60 * 60
    )

    static let expiredAssignment = makeAssignment(
        id: 3,
        title: "MOOC 单元测验复盘",
        publisher: "李老师",
        canSubmit: false,
        submitStatus: false,
        deadlineOffset: -24 * 60 * 60,
        startOffset: -7 * 24 * 60 * 60
    )

    static let groups = [
        TodoAssignmentsData(
            course: mobileDevelopmentCourse,
            assignments: [
                unsubmittedAssignment,
                submittedAssignment,
                expiredAssignment,
            ]
        ),
        TodoAssignmentsData(
            course: softwareEngineeringCourse,
            assignments: [
                makeAssignment(
                    id: 4,
                    title: "需求分析文档初稿",
                    publisher: "李老师",
                    canSubmit: true,
                    submitStatus: false,
                    deadlineOffset: 8 * 60 * 60,
                    startOffset: -2 * 24 * 60 * 60
                )
            ]
        ),
    ]

    static func makeAssignment(
        id: Int,
        title: String,
        publisher: String,
        canSubmit: Bool,
        submitStatus: Bool,
        deadlineOffset: TimeInterval,
        startOffset: TimeInterval
    ) -> MoocHelper.Assignment {
        MoocHelper.Assignment(
            id: id,
            title: title,
            publisher: publisher,
            canSubmit: canSubmit,
            submitStatus: submitStatus,
            deadline: referenceDate.addingTimeInterval(deadlineOffset),
            startTime: referenceDate.addingTimeInterval(startOffset)
        )
    }
}

#Preview("AssignmentsContent") {
    @Previewable @State var errorToast = ToastState.errorTitle
    @Previewable @State var isNotificationDeniedAlertPresented = false

    NavigationStack {
        AssignmentsContent(
            courseGroups: TodoAssignmentsPreviewData.groups,
            isLoading: false,
            isNotificationEnabled: false,
            notificationOffsetHour: 8,
            notificationOffsetMinute: 20,
            errorToast: $errorToast,
            isNotificationDeniedAlertPresented: $isNotificationDeniedAlertPresented,
            onRefreshAssignments: {},
            onSaveNotificationSettings: { _, _, _ in },
            onOpenNotificationSettings: {}
        )
    }
}

#Preview("AssignmentsContent Empty") {
    @Previewable @State var errorToast = ToastState.errorTitle
    @Previewable @State var isNotificationDeniedAlertPresented = false

    NavigationStack {
        AssignmentsContent(
            courseGroups: [],
            isLoading: false,
            isNotificationEnabled: false,
            notificationOffsetHour: 8,
            notificationOffsetMinute: 20,
            errorToast: $errorToast,
            isNotificationDeniedAlertPresented: $isNotificationDeniedAlertPresented,
            onRefreshAssignments: {},
            onSaveNotificationSettings: { _, _, _ in },
            onOpenNotificationSettings: {}
        )
    }
}
