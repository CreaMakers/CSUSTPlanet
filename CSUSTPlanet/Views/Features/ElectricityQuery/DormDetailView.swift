//
//  DormDetailView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import Alamofire
import Charts
import SwiftData
import SwiftUI

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct DormDetailView: View {
    @Bindable var dorm: Dorm

    @Environment(\.modelContext) private var modelContext: ModelContext
    @EnvironmentObject var electricityManager: ElectricityManager

    @State var showErrorAlert: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading = false

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("宿舍信息")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        
                    Divider()
                        
                    InfoRow(label: "宿舍号", value: dorm.room)
                    InfoRow(label: "楼栋", value: dorm.buildingName)
                    InfoRow(label: "校区", value: dorm.campusName)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                    
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("当前电量")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            
                        Spacer()
                            
                        if isLoading {
                            ProgressView()
                        }
                    }
                        
                    Divider()
                        
                    if let record = electricityManager.getLastRecord(records: dorm.records) {
                        VStack(spacing: 8) {
                            HStack {
                                Text("\(String(format: "%.2f", record.electricity))")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.blue)
                                    
                                Text("kWh")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                                
                            Text("更新时间: \(formatDate(record.date))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Text("暂无电量记录")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("电量趋势")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        
                    Divider()
                    
                    if dorm.records.isEmpty {
                        Text("暂无电量记录")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    } else {
                        Chart(dorm.records.sorted(by: { $0.date < $1.date })) { record in
                            LineMark(
                                x: .value("日期", record.date),
                                y: .value("电量", record.electricity)
                            )
                            .interpolationMethod(.catmullRom)
                            .symbol {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 8)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic) { _ in
                                AxisValueLabel(format: .dateTime.year().month().day())
                            }
                        }
                        .frame(height: 200)
                        .padding(.vertical, 8)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                    
                VStack(alignment: .leading, spacing: 12) {
                    Text("历史记录")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        
                    Divider()
                        
                    if dorm.records.isEmpty {
                        Text("暂无历史记录")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(dorm.records.sorted(by: { $0.date > $1.date })) { record in
                            VStack(spacing: 4) {
                                HStack {
                                    Text("\(String(format: "%.2f", record.electricity)) kWh")
                                        .fontWeight(.medium)
                                        
                                    Spacer()
                                        
                                    Text(formatDate(record.date))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 5)
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(record)
                                } label: {
                                    Label("删除记录", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("宿舍电量")
        .navigationBarTitleDisplayMode(.inline)
        .alert("错误", isPresented: $showErrorAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        await refresh()
                    }
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
    }
    
    private func refresh() async {
        isLoading = true
        defer { isLoading = false }
                
        do {
            try await electricityManager.refreshElectricity(dorm: dorm, modelContext: modelContext)
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func formatDate(_ date: Date) -> String {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: date)
    }
}
