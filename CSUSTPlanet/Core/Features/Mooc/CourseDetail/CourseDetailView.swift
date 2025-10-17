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
    @StateObject var viewModel: CourseDetailViewModel

    init(course: MoocHelper.Course) {
        _viewModel = StateObject(wrappedValue: CourseDetailViewModel(course: course))
    }

    init(id: String, name: String) {
        _viewModel = StateObject(wrappedValue: CourseDetailViewModel(id: id, name: name))
    }

    // MARK: - Body

    var body: some View {
        Form {
            courseInfoSection
            homeworksSection
            testsSection
        }
        .toast(isPresenting: $viewModel.isShowingError) {
            AlertToast(type: .error(.red), title: "错误", subTitle: viewModel.errorMessage)
        }
        .sheet(isPresented: $viewModel.isShowingRemindersSettings) {
            ReminderOffsetSettingsView(
                isPresented: $viewModel.isShowingRemindersSettings,
                onConfirm: { hourOffset, minuteOffset in
                    viewModel.addHomeworksToReminders(hourOffset, minuteOffset)
                }
            )
        }
        .task {
            viewModel.loadHomeworks()
            viewModel.loadTests()
        }
        .navigationTitle(viewModel.courseInfo.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: viewModel.loadHomeworks) {
                        Label("刷新作业列表", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isHomeworksLoading)

                    Button(action: viewModel.loadTests) {
                        Label("刷新考试列表", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isTestsLoading)

                    Button(action: {
                        viewModel.isShowingRemindersSettings = true
                    }) {
                        Label("添加作业列表到提醒事项", systemImage: "list.bullet.rectangle")
                    }
                } label: {
                    Label("操作", systemImage: "ellipsis.circle")
                }
            }
        }
        .toast(isPresenting: $viewModel.isShowingSuccess) {
            AlertToast(type: .complete(.green), title: "添加到提醒事项成功")
        }
    }

    // MARK: - Form Sections

    private var courseInfoSection: some View {
        Section(header: Text("课程信息")) {
            if viewModel.isSimplified {
                InfoRow(label: "课程名称", value: viewModel.courseInfo.name)
            } else {
                InfoRow(label: "课程名称", value: viewModel.courseInfo.name)
                InfoRow(label: "课程编号", value: viewModel.courseInfo.number)
                InfoRow(label: "开课院系", value: viewModel.courseInfo.department)
                InfoRow(label: "授课教师", value: viewModel.courseInfo.teacher)
            }
        }
    }

    // MARK: - Homeworks Section

    private var homeworksSection: some View {
        Section(header: Text("作业列表")) {
            if viewModel.isHomeworksLoading {
                HStack {
                    Spacer()
                    ProgressView("加载作业中...")
                    Spacer()
                }
                .padding()
            } else if viewModel.homeworks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 30))
                        .foregroundColor(.secondary)

                    Text("暂无作业")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(viewModel.homeworks.indices, id: \.self) { index in
                    homeworkCard(homework: viewModel.homeworks[index])
                }
            }
        }
    }

    // MARK: - Tests Section

    private var testsSection: some View {
        Section(header: Text("考试列表")) {
            if viewModel.isTestsLoading {
                HStack {
                    Spacer()
                    ProgressView("加载考试中...")
                    Spacer()
                }
                .padding()
            } else if viewModel.tests.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal")
                        .font(.system(size: 30))
                        .foregroundColor(.secondary)

                    Text("暂无考试")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(viewModel.tests.indices, id: \.self) { index in
                    testCard(test: viewModel.tests[index])
                }
            }
        }
    }

    // MARK: - Homework Card

    private func homeworkCard(homework: MoocHelper.Homework) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(homework.title)
                    .font(.headline)
                    .lineLimit(2)

                Spacer()

                // 提交状态标识
                if homework.submitStatus {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                } else if homework.canSubmit {
                    Image(systemName: "circle")
                        .foregroundColor(.orange)
                        .font(.caption)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            HStack {
                Text("发布人:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(homework.publisher)
                    .font(.caption)
                    .foregroundColor(.primary)

                Spacer()
            }

            HStack {
                Label("开始时间", systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(homework.startTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Label("截止时间", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(homework.deadline)
                    .font(.caption)
                    .foregroundColor(homework.submitStatus ? .secondary : .red)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Test Card

    private func testCard(test: MoocHelper.Test) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(test.title)
                    .font(.headline)
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
                Label("开始时间", systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(test.startTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Label("截止时间", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(test.endTime)
                    .font(.caption)
                    .foregroundColor(test.isSubmitted ? .secondary : .red)
            }

            HStack {
                Label("时长限制", systemImage: "timer")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(test.timeLimit) 分钟")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let allowRetake = test.allowRetake {
                HStack {
                    Label("允许次数", systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(allowRetake) 次")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack {
                    Label("允许次数", systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("不限制")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Info Row

    struct InfoRow: View {
        let label: String
        let value: String

        var body: some View {
            HStack {
                Text(label)
                    .foregroundColor(.primary)

                Spacer()

                Text(value)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.trailing)
            }
            .contextMenu {
                Button(action: {
                    UIPasteboard.general.string = value
                }) {
                    Label("复制", systemImage: "doc.on.doc")
                }
            }
        }
    }
}
