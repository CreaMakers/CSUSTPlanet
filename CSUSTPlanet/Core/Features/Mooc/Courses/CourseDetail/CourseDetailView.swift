//
//  CourseDetailView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/8/23.
//

import AlertToast
import CSUSTKit
import SwiftUI

struct CourseDetailView: View {
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif

    let course: MoocHelper.Course

    @State var viewModel = CourseDetailViewModel()
    @State private var isCoursePagePresented = false

    // MARK: - Body

    var body: some View {
        Form {
            courseInfoSection
            assignmentsSection
            examsSection
        }
        .formStyle(.grouped)
        .errorToast($viewModel.errorToast)
        .successToast($viewModel.successToast)
        .sheet(isPresented: $viewModel.isRemindersSettingsPresented) {
            ReminderOffsetSettingsView { hourOffset, minuteOffset in
                Task {
                    await viewModel.addAssignmentsToReminders(hourOffset, minuteOffset)
                }
            }
        }
        #if os(iOS)
        .sheet(isPresented: $isCoursePagePresented) {
            NavigationStack {
                AssignmentsCoursePage(courseID: course.id)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("关闭") {
                            isCoursePagePresented = false
                        }
                    }
                }
            }
        }
        #endif
        .task { await viewModel.loadInitial(course: course) }
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
                Button(action: { viewModel.isRemindersSettingsPresented = true }) {
                    Label("添加作业列表到提醒事项", systemImage: "list.bullet.rectangle")
                }
            }
        }
    }

    // MARK: - Form Sections

    private var courseInfoSection: some View {
        Section {
            FormRow(label: "课程名称", value: course.name)
            if let number = course.number {
                FormRow(label: "课程编号", value: number)
            }
            if let department = course.department {
                FormRow(label: "开课院系", value: department)
            }
            if let teacher = course.teacher {
                FormRow(label: "授课教师", value: teacher)
            }
            Button("前往课程网页") {
                #if os(macOS)
                openWindow(id: AssignmentsCoursePageScene.windowID, value: course.id)
                #else
                isCoursePagePresented = true
                #endif
            }
        } header: {
            Text("课程信息")
        }
    }

    // MARK: - Assignments Section

    private var assignmentsSection: some View {
        Section {
            let assignments = viewModel.displayedAssignments
            if assignments.isEmpty {
                ContentUnavailableView("暂无作业", systemImage: "list.bullet.clipboard")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(assignments.indices, id: \.self) { index in
                    AssignmentInfo(assignment: assignments[index])
                }
            }
        } header: {
            sectionHeader(
                title: "作业列表",
                isLoading: viewModel.isLoadingAssignments,
                assignmentFilterTitle: viewModel.isShowingAllAssignments ? "仅未截止" : "查看全部",
                onToggleAssignmentFilter: { viewModel.isShowingAllAssignments.toggle() }
            ) {
                await viewModel.loadAssignments(course: course)
            }
        }
    }

    // MARK: - Exams Section

    private var examsSection: some View {
        Section {
            if viewModel.exams.isEmpty {
                ContentUnavailableView("暂无考试", systemImage: "pencil.and.ruler")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.exams.indices, id: \.self) { index in
                    testCard(test: viewModel.exams[index])
                }
            }
        } header: {
            sectionHeader(
                title: "考试列表", isLoading: viewModel.isLoadingExams,
                onRefresh: {
                    await viewModel.loadExams(course: course)
                }
            )
        }
    }

    @ViewBuilder
    private func sectionHeader(
        title: String,
        isLoading: Bool,
        assignmentFilterTitle: String? = nil,
        onToggleAssignmentFilter: (() -> Void)? = nil,
        onRefresh: (() async -> Void)? = nil
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            if let assignmentFilterTitle = assignmentFilterTitle, let onToggleAssignmentFilter = onToggleAssignmentFilter {
                Button {
                    withAnimation { onToggleAssignmentFilter() }
                } label: {
                    Text(assignmentFilterTitle)
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            if isLoading {
                ProgressView().smallControlSizeOnMac()
            } else if let onRefresh = onRefresh {
                Button(asyncAction: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
        }
    }

    // MARK: - Test Card

    private func testCard(test: MoocHelper.Exam) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(test.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                Spacer()

                // 提交状态标识
                if test.isSubmitted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }

            HStack {
                Text("开始时间")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(test.startTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("截止时间")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(test.endTime)
                    .font(.caption)
                    .foregroundColor(test.isSubmitted ? .secondary : .red)
            }

            HStack {
                Text("时长限制")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(test.timeLimit) 分钟")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let allowRetake = test.allowRetake {
                HStack {
                    Text("允许次数")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(allowRetake) 次")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack {
                    Text("允许次数")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("不限制")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
