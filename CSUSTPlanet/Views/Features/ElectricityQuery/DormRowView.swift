//
//  DormRowView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import SwiftData
import SwiftUI

struct DormRowView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @EnvironmentObject var electricityManager: ElectricityManager

    @Bindable var dorm: Dorm
    @State var isConfirmationDialogPresented: Bool = false

    @State var isLoading: Bool = false

    @State var showErrorAlert = false
    @State var errorMessage: String = ""

    var body: some View {
        NavigationLink {
            DormDetailView(dorm: dorm)
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

                if isLoading {
                    ProgressView()
                } else if let record = electricityManager.getLastRecord(records: dorm.records) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(String(format: "%.2f", record.electricity)) kWh")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                        Text(formatDate(record.date))
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
                isConfirmationDialogPresented = true
            }) {
                Label("删除", systemImage: "trash")
            }
            .tint(.red)
        }
        .contextMenu {
            Button(action: {
                isConfirmationDialogPresented = true
            }) {
                Label("删除宿舍", systemImage: "trash")
                    .tint(.red)
            }
            Button(action: handleQueryElectricity) {
                Label("查询电量", systemImage: "bolt.fill")
                    .tint(.yellow)
            }
        }
        .alert("删除宿舍", isPresented: $isConfirmationDialogPresented) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                modelContext.delete(dorm)
            }
        } message: {
            Text("确定要删除 \(dorm.room) 宿舍吗？")
        }
        .alert("错误", isPresented: $showErrorAlert) {
            Button("确认", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private let dateFormatter = DateFormatter()

    func formatDate(_ date: Date) -> String {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: date)
    }

    func handleQueryElectricity() {
        isLoading = true
        defer {
            isLoading = false
        }
        Task {
            do {
                try await electricityManager.refreshElectricity(dorm: dorm, modelContext: modelContext)
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}
