//
//  DormDetailView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import Alamofire
import Charts
import RealmSwift
import SwiftUI

struct DormDetailView: View {
    @ObservedObject var viewModel: DormElectricityViewModel
    @ObservedRealmObject var dorm: Dorm

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

    var body: some View {
        Form {
            dormInfoSection

            if viewModel.isQueryingElectricity {
                Section {
                    ProgressView("正在查询电量...")
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                currentElectricitySection

                if !dorm.records.isEmpty {
                    electricityTrendSection
                    historyRecordsSection
                } else {
                    emptyStateSection
                }
            }
        }
        .navigationTitle("宿舍电量")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Menu {
                        Button(action: viewModel.handleShowTerms) {
                            Label("设置定时查询", systemImage: "bell").tint(.blue)
                        }
                        .disabled(viewModel.isScheduleLoading || dorm.schedule != nil)

                        Button(action: { _ = viewModel.removeSchedule(dorm) }) {
                            Label("取消定时查询", systemImage: "bell.slash").tint(.red)
                        }
                        .disabled(viewModel.isScheduleLoading || dorm.schedule == nil)
                    } label: {
                        Label("定时查询", systemImage: "clock").tint(.purple)
                        if viewModel.isScheduleLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                    }

                    Button(action: { viewModel.deleteAllRecords(dorm) }) {
                        Label("清除历史", systemImage: "trash").tint(.red)
                    }
                } label: {
                    Label("操作", systemImage: "ellipsis.circle")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: { viewModel.handleQueryElectricity(dorm) }) {
                    Label("查询电量", systemImage: "bolt.fill")
                }
                .tint(.yellow)
                .disabled(viewModel.isQueryingElectricity)
            }
        }
    }

    // MARK: - Form Sections

    private var dormInfoSection: some View {
        Section(header: Text("宿舍信息")) {
            InfoRow(icon: "house.fill", iconColor: .blue, label: "宿舍号", value: dorm.room)
            InfoRow(icon: "building.fill", iconColor: .green, label: "楼栋", value: dorm.buildingName)
            InfoRow(icon: "map.fill", iconColor: .orange, label: "校区", value: dorm.campusName)

            if let schedule = dorm.schedule {
                InfoRow(icon: "clock.fill", iconColor: .purple, label: "定时查询时间", value: String(format: "%02d:%02d", schedule.hour, schedule.minute))
            }
        }
    }

    private var currentElectricitySection: some View {
        Section(header: Text("当前电量")) {
            if let record = dorm.latestRecord {
                VStack(spacing: 8) {
                    HStack {
                        Text("\(String(format: "%.2f", record.electricity))")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(ColorHelper.electricityColor(electricity: record.electricity))

                        Text("kWh")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()
                    }

                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.gray)

                        Text("更新时间: \(viewModel.formatDate(record.date))")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                }
                .padding(.vertical, 4)
            } else {
                Text("暂无电量记录")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var electricityTrendSection: some View {
        Section(header: Text("电量趋势")) {
            Chart(dorm.records.sorted(by: { $0.date < $1.date })) { record in
                LineMark(
                    x: .value("日期", record.date),
                    y: .value("电量", record.electricity)
                )
                .interpolationMethod(.catmullRom)
                .symbol {
                    if dorm.records.count <= 1 {
                        Circle()
                            .frame(width: 8)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .frame(height: 200)
            .padding(.vertical, 8)
        }
    }

    private var historyRecordsSection: some View {
        Section(header: Text("历史记录")) {
            ForEach(dorm.records.sorted(by: { $0.date > $1.date })) { record in
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(String(format: "%.2f", record.electricity)) kWh")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(viewModel.formatDate(record.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
                .contextMenu {
                    Button(role: .destructive) {
                        viewModel.deleteRecord(record: record)
                    } label: {
                        Label("删除记录", systemImage: "trash")
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        viewModel.deleteRecord(record: record)
                    } label: {
                        Label("删除记录", systemImage: "trash")
                    }
                }
            }
        }
    }

    private var emptyStateSection: some View {
        Section {
            VStack(spacing: 8) {
                Image(systemName: "bolt.slash.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)

                Text("暂无电量记录")
                    .font(.headline)

                Text("点击右上角按钮查询电量")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
}
