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

struct DormDetailView: View {
    @ObservedObject var viewModel: DormElectricityViewModel
    
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

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                dormInfoSection
                electricityInfoSection
                electricityTrendSection
                historyRecordsSection
            }
            .padding(.vertical)
        }
        .navigationTitle("宿舍电量")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: viewModel.handleQueryElectricity) {
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
                        .disabled(viewModel.isScheduleLoading || viewModel.isScheduleEnabled)
                        Button(action: { _ = viewModel.removeSchedule() }) {
                            Label("取消定时查询", systemImage: "bell.slash")
                                .tint(.red)
                        }
                        .disabled(viewModel.isScheduleLoading || !viewModel.isScheduleEnabled)
                    } label: {
                        Label("定时查询", systemImage: "clock")
                            .tint(.purple)
                        if viewModel.isScheduleLoading {
                            ProgressView("加载中...")
                                .progressViewStyle(.circular)
                        }
                    }
                } label: {
                    Label("操作", systemImage: "ellipsis.circle")
                }
            }
        }
    }

    // MARK: - Subviews

    private var dormInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("宿舍信息")
                .font(.headline)
                .foregroundColor(.secondary)
                
            Divider()
                
            InfoRow(label: "宿舍号", value: viewModel.dorm.room)
            InfoRow(label: "楼栋", value: viewModel.dorm.buildingName)
            InfoRow(label: "校区", value: viewModel.dorm.campusName)
            if viewModel.isScheduleEnabled, let scheduleHour = viewModel.dorm.scheduleHour, let scheduleMinute = viewModel.dorm.scheduleMinute {
                InfoRow(label: "定时查询", value: "已启用")
                InfoRow(label: "定时查询时间", value: String(format: "%02d:%02d", scheduleHour, scheduleMinute))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    private var electricityInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("当前电量")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    
                Spacer()
                    
                if viewModel.isQueryingElectricity {
                    ProgressView()
                }
            }
                
            Divider()
                
            if let record = viewModel.getLastRecord() {
                currentElectricityView(record: record)
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
    }

    private func currentElectricityView(record: ElectricityRecord) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(String(format: "%.2f", record.electricity))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                    
                Text("kWh")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
                
            Text("更新时间: \(viewModel.formatDate(record.date))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var electricityTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("电量趋势")
                .font(.headline)
                .foregroundColor(.secondary)
                
            Divider()
            
            if viewModel.dorm.records.isEmpty {
                Text("暂无电量记录")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                electricityChart
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    private var electricityChart: some View {
        Chart(viewModel.dorm.records.sorted(by: { $0.date < $1.date })) { record in
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

    private var historyRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("历史记录")
                .font(.headline)
                .foregroundColor(.secondary)
                
            Divider()
                
            if viewModel.dorm.records.isEmpty {
                Text("暂无历史记录")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.dorm.records.sorted(by: { $0.date > $1.date })) { record in
                    historyRecordRow(record: record)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    private func historyRecordRow(record: ElectricityRecord) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text("\(String(format: "%.2f", record.electricity)) kWh")
                    .fontWeight(.medium)
                    
                Spacer()
                    
                Text(viewModel.formatDate(record.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 5)
        .contextMenu {
            Button(role: .destructive) {
                viewModel.deleteRecord(record: record)
            } label: {
                Label("删除记录", systemImage: "trash")
            }
        }
    }
}
