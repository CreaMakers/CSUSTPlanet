//
//  TodoAssignmentsContent.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/20.
//

import CSUSTKit
import SwiftUI

struct TodoAssignmentsContent: View {
    let courseGroups: [TodoAssignmentsData]?

    let isLoadingAssignments: Bool

    @Binding var errorToast: ToastState
    @Binding var selectedCourseID: String?
    @Binding var isCoursePagePresented: Bool
    @Binding var isNotificationSettingsPresented: Bool
    @Binding var isNotificationDeniedAlertPresented: Bool

    let onRefreshAssignments: () async -> Void
    let onSaveNotificationSettings: (Bool, Int, Int) async -> Void
    let onOpenCoursePage: (String) -> Void
    let onOpenNotificationSettings: () -> Void

    private var submittableAssignmentsCount: Int {
        return (courseGroups ?? []).reduce(0) { count, group in
            count + group.assignments.filter { $0.isSubmittable(referenceDate: .now) }.count
        }
    }

    var body: some View {
        Group {
            if let courseGroups, !courseGroups.isEmpty {
                CustomScrollView {
                    ForEach(courseGroups, id: \.course.id) { group in
                        TodoAssignmentsCourseSection(
                            group: group,
                            onOpenCoursePage: onOpenCoursePage
                        )
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
            TodoAssignmentsNotificationSettings(
                isEnabled: MMKVHelper.TodoAssignments.isNotificationEnabled,
                reminderOffsetHour: MMKVHelper.TodoAssignments.notificationOffsetHour,
                reminderOffsetMinute: MMKVHelper.TodoAssignments.notificationOffsetMinute,
                onCancel: {
                    isNotificationSettingsPresented = false
                },
                onSave: { enabled, hour, minute in
                    await onSaveNotificationSettings(enabled, hour, minute)
                    isNotificationSettingsPresented = false
                }
            )
        }
        #if os(iOS)
        .sheet(isPresented: $isCoursePagePresented) {
            NavigationStack {
                if let courseID = selectedCourseID {
                    TodoAssignmentsCoursePage(courseID: courseID)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("关闭") {
                                isCoursePagePresented = false
                            }
                        }
                    }
                }
            }
        }
        #endif
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
                    if isLoadingAssignments {
                        ProgressView().smallControlSizeOnMac()
                    } else {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(isLoadingAssignments)
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

#Preview("TodoAssignmentsContent") {
    @Previewable @State var errorToast = ToastState.errorTitle
    @Previewable @State var selectedCourseID: String?
    @Previewable @State var isCoursePagePresented = false
    @Previewable @State var isNotificationSettingsPresented = false
    @Previewable @State var isNotificationDeniedAlertPresented = false

    NavigationStack {
        TodoAssignmentsContent(
            courseGroups: TodoAssignmentsPreviewData.groups,
            isLoadingAssignments: false,
            errorToast: $errorToast,
            selectedCourseID: $selectedCourseID,
            isCoursePagePresented: $isCoursePagePresented,
            isNotificationSettingsPresented: $isNotificationSettingsPresented,
            isNotificationDeniedAlertPresented: $isNotificationDeniedAlertPresented,
            onRefreshAssignments: {},
            onSaveNotificationSettings: { _, _, _ in },
            onOpenCoursePage: { _ in },
            onOpenNotificationSettings: {}
        )
    }
}

#Preview("TodoAssignmentsContent Empty") {
    @Previewable @State var errorToast = ToastState.errorTitle
    @Previewable @State var selectedCourseID: String?
    @Previewable @State var isCoursePagePresented = false
    @Previewable @State var isNotificationSettingsPresented = false
    @Previewable @State var isNotificationDeniedAlertPresented = false

    NavigationStack {
        TodoAssignmentsContent(
            courseGroups: [],
            isLoadingAssignments: false,
            errorToast: $errorToast,
            selectedCourseID: $selectedCourseID,
            isCoursePagePresented: $isCoursePagePresented,
            isNotificationSettingsPresented: $isNotificationSettingsPresented,
            isNotificationDeniedAlertPresented: $isNotificationDeniedAlertPresented,
            onRefreshAssignments: {},
            onSaveNotificationSettings: { _, _, _ in },
            onOpenCoursePage: { _ in },
            onOpenNotificationSettings: {}
        )
    }
}
