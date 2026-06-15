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
    @State var viewModel = ExamScheduleViewModel()

    // MARK: - Body

    var body: some View {
        Group {
            if let data = viewModel.examData, !data.value.isEmpty {
                CustomScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(data.value, id: \.courseID) { exam in
                            examCard(exam: exam).id(exam.courseID)
                        }
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView("暂无考试安排", systemImage: "calendar.badge.exclamationmark", description: Text("当前筛选条件下没有找到考试安排"))
            }
        }
        .task { await viewModel.loadInitial() }
        .safeRefreshable { await viewModel.loadExams() }
        .errorToast($viewModel.errorToast)
        .successToast($viewModel.successToast)
        .loadingToast($viewModel.loadingToast)
        .sheet(isPresented: $viewModel.isFilterPresented) { filterView.presentationDetents([.medium, .large]) }
        .alert("添加日历", isPresented: $viewModel.isAddToCalendarAlertPresented) {
            Button(asyncAction: viewModel.addToCalendar) {
                Text("确认添加")
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("是否将所有考试安排添加到系统日历？")
        }
        .toolbar {
            ToolbarItemGroup(placement: .secondaryAction) {
                Button(action: { viewModel.isFilterPresented.toggle() }) {
                    Label("高级查询", systemImage: "slider.horizontal.3")
                }
                .disabled(viewModel.isLoadingExams)

                Button(action: { viewModel.isAddToCalendarAlertPresented = true }) {
                    Label("全部添加到日历", systemImage: "calendar.badge.plus")
                }
                .disabled(viewModel.examData?.value.isEmpty == true || viewModel.isLoadingExams)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(asyncAction: viewModel.loadExams) {
                    if viewModel.isLoadingExams {
                        ProgressView().smallControlSizeOnMac()
                    } else {
                        Label("查询", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(viewModel.isLoadingExams)
            }
        }
        .navigationTitle("考试安排")
        .navigationSubtitleCompat("共 \(viewModel.examData?.value.count ?? 0) 门考试")
    }

    // MARK: - Exam Card

    @ViewBuilder
    func examCard(exam: EduHelper.Exam) -> some View {
        let finished = viewModel.isExamFinished(exam)
        let daysLeft = viewModel.daysUntilExam(exam)
        let dateStyle = finished ? RelativeDateStyle.secondary : RelativeDateStyle.scheduled(for: exam.examStartTime)
        let statusText: String =
            if finished {
                "已结束"
            } else if daysLeft == 0 {
                "今天"
            } else if daysLeft == 1 {
                "明天"
            } else if daysLeft == 2 {
                "后天"
            } else {
                "还有 \(daysLeft) 天"
            }

        CustomGroupBox {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Text(exam.courseName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(finished ? .secondary : .primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    RelativeDateBadge(
                        text: statusText,
                        style: dateStyle,
                        font: .caption.bold()
                    )
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
        }
        .opacity(finished ? 0.6 : 1.0)
        .saturation(finished ? 0.0 : 1.0)
    }

    // MARK: - Detail Row

    @ViewBuilder
    func detailRow(icon: String, color: Color, text: String, finished: Bool) -> some View {
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
}

extension ExamScheduleView {
    // MARK: - Filter View

    @ViewBuilder
    var filterView: some View {
        NavigationStack {
            Form {
                Section(header: Text("学期选择")) {
                    Picker("学期", selection: $viewModel.selectedSemester) {
                        Text("默认学期").tag(nil as String?)
                        ForEach(viewModel.availableSemesters, id: \.self) { semester in
                            Text(semester).tag(semester as String?)
                        }
                    }
                    #if os(iOS)
                    .pickerStyle(.wheel)
                    #elseif os(macOS)
                    .pickerStyle(.menu)
                    #endif
                    HStack {
                        Button(asyncAction: viewModel.loadAvailableSemesters) {
                            Text("刷新学期列表")
                        }
                        if viewModel.isLoadingSemesters {
                            Spacer()
                            ProgressView().smallControlSizeOnMac()
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
            .formStyle(.grouped)
            .navigationTitle("高级查询")
            .inlineToolbarTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        viewModel.isFilterPresented = false
                        await viewModel.loadExams()
                    }
                }
            }
        }
    }
}
