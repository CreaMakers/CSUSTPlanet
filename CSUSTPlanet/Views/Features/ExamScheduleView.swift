//
//  ExamScheduleView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import CSUSTKit
import SwiftUI

struct ExamScheduleView: View {
    @StateObject var viewModel: ExamScheduleViewModel
    
    struct InfoRow: View {
        let icon: String
        let iconColor: Color
        let label: String
        let value: String
        
        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
    
    init(authManager: AuthManager) {
        _viewModel = StateObject(wrappedValue: ExamScheduleViewModel(eduHelper: authManager.eduHelper))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                filterSection
                
                if viewModel.isQuerying {
                    ProgressView()
                        .padding(.vertical, 40)
                } else if viewModel.examSchedule.isEmpty {
                    emptyStateView
                } else {
                    examListSection
                }
            }
            .padding(.vertical)
        }
        .alert("错误", isPresented: $viewModel.isShowingError) {
            Button("确认", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("添加日历", isPresented: $viewModel.isShowingAddToCalendarAlert) {
            Button(action: viewModel.addAllToCalendar) {
                Text("确认添加")
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("是否将所有考试安排添加到系统日历？")
        }
        .task {
            viewModel.loadAvailableSemesters()
            viewModel.getExams()
        }
        .navigationTitle("考试安排")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.getExams()
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isQuerying)
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.isShowingAddToCalendarAlert = true
                } label: {
                    Label("添加到日历", systemImage: "calendar.badge.plus")
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("筛选条件")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Divider()
            
            HStack {
                Text("学期")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                if viewModel.isSemestersLoading {
                    ProgressView("加载中...")
                } else {
                    Button(action: viewModel.loadAvailableSemesters) {
                        Label("刷新学期", systemImage: "arrow.clockwise")
                    }
                    Picker("学期", selection: $viewModel.selectedSemesters) {
                        Text("默认学期").tag(nil as String?)
                        ForEach(viewModel.availableSemesters, id: \.self) { semester in
                            Text(semester).tag(semester as String?)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            HStack {
                Text("考试类型")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Picker("考试类型", selection: $viewModel.selectedSemesterType) {
                    Text("全部类型").tag(nil as SemesterType?)
                    Text("期初考试").tag(SemesterType.beginning as SemesterType?)
                    Text("期中考试").tag(SemesterType.middle as SemesterType?)
                    Text("期末考试").tag(SemesterType.end as SemesterType?)
                }
                .pickerStyle(.menu)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var emptyStateView: some View {
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
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal)
    }
    
    private var examListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("考试安排")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ForEach(viewModel.examSchedule, id: \.courseID) { exam in
                Divider()
                examCard(exam: exam)
                    .padding(.vertical, 8)
                    .contextMenu {
                        Button(action: {
                            viewModel.addToCalendar(exam: exam)
                        }) {
                            Label("添加到日历", systemImage: "calendar.badge.plus")
                        }
                    }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private func examCard(exam: Exam) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(exam.courseName)
                .font(.headline)
                .lineLimit(1)
                .padding(.bottom)
            
            InfoRow(icon: "clock", iconColor: .blue, label: "考试时间", value: exam.examTime)
            InfoRow(icon: "building.columns", iconColor: .green, label: "考场", value: exam.examRoom)
            if !exam.seatNumber.isEmpty {
                InfoRow(icon: "number", iconColor: .orange, label: "座位号", value: exam.seatNumber)
            }
            if !exam.teacher.isEmpty {
                InfoRow(icon: "person", iconColor: .purple, label: "授课教师", value: exam.teacher)
            }
            if !exam.admissionTicketNumber.isEmpty {
                InfoRow(icon: "doc.text", iconColor: .red, label: "准考证号", value: exam.admissionTicketNumber)
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
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        ExamScheduleView(authManager: AuthManager())
    }
}
