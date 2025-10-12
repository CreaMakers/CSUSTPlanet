//
//  DormRowView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import AlertToast
import SwiftData
import SwiftUI

struct DormRowView: View {
    @StateObject var viewModel = DormElectricityViewModel()
    @Bindable var dorm: Dorm

    var body: some View {
        NavigationLink {
            DormDetailView(viewModel: viewModel, dorm: dorm)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("宿舍号：\(dorm.room)")
                        .font(.headline)
                    Text("楼栋：\(dorm.buildingName)")
                        .font(.subheadline)
                    Text("校区：\(dorm.campusName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if viewModel.isQueryingElectricity {
                    ProgressView()
                } else if let record = dorm.lastRecord {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(String(format: "%.2f", record.electricity)) kWh")
                            .font(.headline)
                            .foregroundStyle(ColorHelper.electricityColor(electricity: record.electricity))
                        Text(viewModel.formatDate(record.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("暂无电量记录")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: { viewModel.handleQueryElectricity(dorm) }) {
                Label("查询", systemImage: "bolt.fill")
            }
            .tint(.yellow)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(action: {
                viewModel.isConfirmationDialogPresented = true
            }) {
                Label("删除", systemImage: "trash")
            }
            .tint(.red)
        }
        .contextMenu {
            Button(action: {
                viewModel.isConfirmationDialogPresented = true
            }) {
                Label("删除宿舍", systemImage: "trash")
                    .tint(.red)
            }
            Button(action: { viewModel.handleQueryElectricity(dorm) }) {
                Label("查询电量", systemImage: "bolt.fill")
                    .tint(.yellow)
            }
            .disabled(viewModel.isQueryingElectricity)
            Divider()
            Menu {
                Button(action: viewModel.handleShowTerms) {
                    Label("设置定时查询", systemImage: "bell")
                        .tint(.blue)
                }
                .disabled(viewModel.isScheduleLoading || dorm.scheduleId != nil)
                Button(action: { _ = viewModel.removeSchedule(dorm) }) {
                    Label("取消定时查询", systemImage: "bell.slash")
                        .tint(.red)
                }
                .disabled(viewModel.isScheduleLoading || dorm.scheduleId == nil)
            } label: {
                Label("定时查询", systemImage: "clock")
                    .tint(.purple)
                if viewModel.isScheduleLoading {
                    ProgressView("加载中...")
                        .progressViewStyle(.circular)
                }
            }
        }
        .alert("删除宿舍", isPresented: $viewModel.isConfirmationDialogPresented) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive, action: { viewModel.deleteDorm(dorm) })
        } message: {
            Text("确定要删除 \(dorm.room) 宿舍吗？")
        }
        .alert(isPresented: $viewModel.isShowingError) {
            Alert(title: Text("错误"), message: Text(viewModel.errorMessage), dismissButton: .default(Text("确定")))
        }
        .sheet(isPresented: $viewModel.isTermsPresented) {
            ElectricityTermsView(isPresented: $viewModel.isTermsPresented, onAgree: viewModel.handleTermsAgree)
        }
        .sheet(isPresented: $viewModel.isShowNotificationSettings) {
            NotificationSettingsView(
                isPresented: $viewModel.isShowNotificationSettings,
                onConfirm: { hour, minute in
                    viewModel.handleNotificationSettings(dorm, scheduleHour: hour, scheduleMinute: minute)
                }
            )
        }
        .task {
            viewModel.loadSchedule(dorm)
        }
    }
}
