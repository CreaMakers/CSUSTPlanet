//
//  ExamScheduleView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import AlertToast
import CSUSTKit
import SwiftUI

struct ExamScheduleView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject var viewModel = ExamScheduleViewModel()

    @State private var now = Date()

    // MARK: - Filter View

    @ViewBuilder
    private var filterView: some View {
        NavigationStack {
            Form {
                Section(header: Text("学期选择")) {
                    Picker("学期", selection: $viewModel.selectedSemesters) {
                        Text("默认学期").tag(nil as String?)
                        ForEach(viewModel.availableSemesters, id: \.self) { semester in
                            Text(semester).tag(semester as String?)
                        }
                    }
                    .pickerStyle(.wheel)
                    HStack {
                        Button(action: viewModel.loadAvailableSemesters) {
                            Text("刷新学期列表")
                        }
                        if viewModel.isSemestersLoading {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                Section(header: Text("筛选条件")) {
                    Picker("考试类型", selection: $viewModel.selectedSemesterType) {
                        Text("全部类型").tag(nil as EduHelper.SemesterType?)
                        ForEach(EduHelper.SemesterType.allCases, id: \.self) { semesterType in
                            Text(semesterType.rawValue).tag(semesterType as EduHelper.SemesterType?)
                        }
                    }
                }
            }
            .navigationTitle("高级查询")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        viewModel.isShowingFilter = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        viewModel.isShowingFilter = false
                        viewModel.loadExams()
                    }
                }
            }
        }
    }

    // MARK: - Empty State Section

    @ViewBuilder
    private var emptyStateSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
                .padding(.bottom, 8)

            Text("暂无考试安排")
                .font(.headline)

            Text("当前筛选条件下没有找到考试安排")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Logic Helpers

    private func isExamFinished(_ exam: EduHelper.Exam) -> Bool {
        return now > exam.examEndTime
    }

    private func daysUntilExam(_ exam: EduHelper.Exam) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        let examDay = calendar.startOfDay(for: exam.examStartTime)
        let components = calendar.dateComponents([.day], from: startOfDay, to: examDay)
        return components.day ?? 0
    }

    // MARK: - Exam Card

    @ViewBuilder
    private func examCard(exam: EduHelper.Exam) -> some View {
        let finished = isExamFinished(exam)
        let daysLeft = daysUntilExam(exam)

        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top) {
                Text(exam.courseName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(finished ? .secondary : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()

                // 状态/倒计时 Badge
                if finished {
                    Text("已结束")
                        .font(.caption.bold())
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.15), in: Capsule())
                } else {
                    if daysLeft == 0 {
                        Text("今天")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red, in: Capsule())
                    } else if daysLeft == 1 {
                        Text("明天")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange, in: Capsule())
                    } else {
                        Text("还有 \(daysLeft) 天")
                            .font(.caption.bold())
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1), in: Capsule())
                    }
                }
            }
            .padding(.bottom, 12)

            Divider()
                .padding(.bottom, 12)

            // Info Rows
            VStack(alignment: .leading, spacing: 10) {
                detailRow(icon: "clock.fill", color: .blue, text: exam.examTime, finished: finished)

                HStack(spacing: 0) {
                    detailRow(icon: "building.columns.fill", color: .green, text: exam.examRoom, finished: finished)
                    Spacer()
                    if !exam.seatNumber.isEmpty {
                        detailRow(icon: "number.square.fill", color: .orange, text: "座号: \(exam.seatNumber)", finished: finished)
                    }
                }

                if !exam.teacher.isEmpty {
                    detailRow(icon: "person.fill", color: .purple, text: exam.teacher, finished: finished)
                }

                if !exam.admissionTicketNumber.isEmpty {
                    detailRow(icon: "doc.text.fill", color: .red, text: "准考证: \(exam.admissionTicketNumber)", finished: finished)
                }

                if !exam.remarks.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundColor(finished ? .gray : .secondary)
                            .frame(width: 16)
                        Text(exam.remarks)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        // 已结束状态：降低透明度，置灰
        .opacity(finished ? 0.6 : 1.0)
        .saturation(finished ? 0.0 : 1.0)
        .contextMenu {
            Button(action: {
                viewModel.addToCalendar(exam: exam)
            }) {
                Label("添加到日历", systemImage: "calendar.badge.plus")
            }
        }
    }

    // 辅助视图：详情行
    @ViewBuilder
    private func detailRow(icon: String, color: Color, text: String, finished: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(finished ? .gray : color)
                .frame(width: 16)

            Text(text)
                .font(.subheadline)
                .foregroundColor(finished ? .secondary : .primary)
                .lineLimit(1)
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if let data = viewModel.data, !data.value.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(data.value, id: \.courseID) { exam in
                                examCard(exam: exam)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical)
                    }
                    .refreshable {
                        viewModel.loadExams()
                    }
                } else {
                    emptyStateSection
                }
            }
        }
        .onAppear {
            now = Date()
        }
        .toast(isPresenting: $viewModel.isShowingError) {
            AlertToast(type: .error(.red), title: "错误", subTitle: viewModel.errorMessage)
        }
        .toast(isPresenting: $viewModel.isShowingSuccess) {
            AlertToast(type: .complete(.green), title: viewModel.successMessage)
        }
        .toast(isPresenting: $viewModel.isShowingWarning) {
            AlertToast(displayMode: .banner(.slide), type: .systemImage("exclamationmark.triangle", .yellow), title: "警告", subTitle: viewModel.warningMessage)
        }
        .task { viewModel.task() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { viewModel.isShowingFilter.toggle() }) {
                        Label("高级查询", systemImage: "slider.horizontal.3")
                    }
                    Button(action: { viewModel.isShowingAddToCalendarAlert = true }) {
                        Label("全部添加到日历", systemImage: "calendar.badge.plus")
                    }
                    .disabled(viewModel.data == nil)
                } label: {
                    Label("更多操作", systemImage: "ellipsis.circle")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.9, anchor: .center)
                } else {
                    Button(action: { viewModel.loadExams() }) {
                        Label("查询", systemImage: "magnifyingglass")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingFilter) { filterView }
        .alert("添加日历", isPresented: $viewModel.isShowingAddToCalendarAlert) {
            Button(action: viewModel.addAllToCalendar) {
                Text("确认添加")
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("是否将所有考试安排添加到系统日历？")
        }
        .navigationTitle("考试安排")
        .toolbarTitleDisplayMode(.inline)
    }
}
