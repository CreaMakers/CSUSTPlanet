//
//  DormRowView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import SwiftData
import SwiftUI

struct DormRowView: View {
    @StateObject var viewModel: DormElectricityViewModel

    init(modelContext: ModelContext, dorm: Dorm) {
        _viewModel = StateObject(
            wrappedValue: DormElectricityViewModel(modelContext: modelContext, dorm: dorm)
        )
    }

    var body: some View {
        NavigationLink {
            DormDetailView(viewModel: viewModel)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("宿舍号：\(viewModel.dorm.room)")
                        .font(.headline)
                    Text("楼栋：\(viewModel.dorm.buildingName)")
                        .font(.subheadline)
                    Text("校区：\(viewModel.dorm.campusName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if viewModel.isQueryingElectricity {
                    ProgressView()
                } else if let record = viewModel.getLastRecord() {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(String(format: "%.2f", record.electricity)) kWh")
                            .font(.headline)
                            .foregroundColor(.accentColor)
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
            Button(action: viewModel.handleQueryElectricity) {
                Label("查询电量", systemImage: "bolt.fill")
                    .tint(.yellow)
            }
            Button(action: viewModel.handleShowTerms) {
                Label("定时通知", systemImage: "bell")
                    .tint(.blue)
            }
        }
        .alert("删除宿舍", isPresented: $viewModel.isConfirmationDialogPresented) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive, action: viewModel.deleteDorm)
        } message: {
            Text("确定要删除 \(viewModel.dorm.room) 宿舍吗？")
        }
        .alert("错误", isPresented: $viewModel.isShowingError) {
            Button("确认", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $viewModel.isTermsPresented) {
            ElectricityTermsView(isPresented: $viewModel.isTermsPresented, onAgree: viewModel.handleTermsAgree)
        }
    }
}
