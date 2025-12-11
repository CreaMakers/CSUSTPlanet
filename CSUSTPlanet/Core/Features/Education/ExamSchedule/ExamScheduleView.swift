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

    // MARK: - Exam Card

    @ViewBuilder
    private func examCardContent(exam: EduHelper.Exam) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(exam.courseName)
                .font(.headline)
                .lineLimit(1)
                .padding(.bottom, 8)

            InfoRow(icon: ("clock", .blue), label: "考试时间", value: exam.examTime)
            InfoRow(icon: ("building.columns", .green), label: "考场", value: exam.examRoom)

            if !exam.seatNumber.isEmpty {
                InfoRow(icon: ("number", .orange), label: "座位号", value: exam.seatNumber)
            }

            if !exam.teacher.isEmpty {
                InfoRow(icon: ("person", .purple), label: "授课教师", value: exam.teacher)
            }

            if !exam.admissionTicketNumber.isEmpty {
                InfoRow(icon: ("doc.text", .red), label: "准考证号", value: exam.admissionTicketNumber)
            }

            if !exam.remarks.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "note.text")
                        .foregroundColor(.gray)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("备注")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(exam.remarks)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func examCard(exam: EduHelper.Exam) -> some View {
        examCardContent(exam: exam)
            .contextMenu {
                Button(action: {
                    viewModel.addToCalendar(exam: exam)
                }) {
                    Label("添加到日历", systemImage: "calendar.badge.plus")
                }
            }
    }

    // MARK: - Shareable View

    @ViewBuilder
    private var shareableView: some View {
        VStack(spacing: 0) {
            Text("考试安排")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.vertical)

            Divider()

            if let data = viewModel.data {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(data.value, id: \.courseID) { exam in
                        examCardContent(exam: exam)
                            .padding(.horizontal)
                        Divider()
                    }
                }
            } else {
                emptyStateSection
                    .background(Color(.systemGroupedBackground))
            }
        }
        .padding(.vertical)
        .frame(width: UIScreen.main.bounds.width)
        .background(Color(.systemGroupedBackground))
        .environment(\.colorScheme, colorScheme)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if let data = viewModel.data, !data.value.isEmpty {
                List {
                    ForEach(data.value, id: \.courseID) { exam in
                        examCard(exam: exam)
                    }
                }
                .listStyle(.insetGrouped)
            } else {
                emptyStateSection
                    .background(Color(.systemGroupedBackground))
            }
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
                    Button(action: { viewModel.showShareSheet(shareableView) }) {
                        Label("分享", systemImage: "square.and.arrow.up")
                    }
                    .disabled(viewModel.isLoading)
                    Button(action: { viewModel.saveToPhotoAlbum(shareableView) }) {
                        Label("保存结果到相册", systemImage: "photo")
                    }
                    .disabled(viewModel.isLoading)
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
        .sheet(isPresented: $viewModel.isShowingShareSheet) { ShareSheet(items: [viewModel.shareContent!]) }
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
