//
//  DormCardView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import AlertToast
import Charts
import SwiftData
import SwiftUI

struct DormCardView: View {
    @StateObject var viewModel = DormElectricityViewModel()
    @Bindable var dorm: Dorm

    private var electricityColor: Color {
        guard let record = dorm.lastRecord else { return .primary }
        return ColorHelper.electricityColor(electricity: record.electricity)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)

            NavigationLink(destination: DormDetailView(viewModel: viewModel, dorm: dorm)) {
                EmptyView()
            }
            .opacity(0)

            // 卡片内容
            VStack(alignment: .leading, spacing: 12) {
                // MARK: - Header
                HStack {
                    HStack(spacing: 6) {
                        Text(dorm.room)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        if dorm.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }

                        if dorm.scheduleEnabled {
                            Image(systemName: "bell.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary.opacity(0.5))
                        }
                    }

                    Spacer()

                    Button(action: { viewModel.handleQueryElectricity(dorm) }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(viewModel.isQueryingElectricity ? Color.secondary : .blue)
                            .rotationEffect(.degrees(viewModel.isQueryingElectricity ? 360 : 0))
                            .animation(viewModel.isQueryingElectricity ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isQueryingElectricity)
                    }
                    .buttonStyle(.plain)
                }

                // MARK: - Body
                if let record = dorm.lastRecord {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(String(format: "%.2f", record.electricity))
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(electricityColor)
                            .contentTransition(.numericText())

                        Text("kWh")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 2)
                    }
                } else {
                    Text("暂无数据")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                }

                // MARK: - Footer
                HStack {
                    Text("\(dorm.campusName) · \(dorm.buildingName)")

                    Spacer()

                    if let record = dorm.lastRecord {
                        Text(viewModel.getExhaustionInfo(from: dorm.records) ?? viewModel.formatDate(record.date))
                    }
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
            .padding(16)
        }
        // MARK: - 交互修饰符
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: { viewModel.handleQueryElectricity(dorm) }) {
                Label("查询", systemImage: "bolt.fill")
            }
            .tint(.yellow)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(
                role: .destructive,
                action: {
                    viewModel.isConfirmationDialogPresented = true
                }
            ) {
                Label("删除", systemImage: "trash")
            }
        }
        .contextMenu {
            Button(action: { viewModel.isConfirmationDialogPresented = true }) {
                Label("删除宿舍", systemImage: "trash")
                    .tint(.red)
            }
            Button(action: { viewModel.toggleFavorite(dorm) }) {
                Label(dorm.isFavorite ? "取消收藏" : "设为常用", systemImage: dorm.isFavorite ? "star.slash" : "star")
            }
            Button(action: { viewModel.handleQueryElectricity(dorm) }) {
                Label("查询电量", systemImage: "bolt.fill")
                    .tint(.yellow)
            }
            .disabled(viewModel.isQueryingElectricity)
            Divider()
            Menu {
                Button(action: { viewModel.isShowNotificationSettings = true }) {
                    Label("设置定时查询", systemImage: "bell")
                        .tint(.blue)
                }
                .disabled(viewModel.isScheduleLoading || dorm.scheduleEnabled)
                Button(action: { viewModel.isCancelScheduleAlertPresented = true }) {
                    Label("取消定时查询", systemImage: "bell.slash")
                        .tint(.red)
                }
                .disabled(viewModel.isScheduleLoading || !dorm.scheduleEnabled)
            } label: {
                Label("定时查询", systemImage: "clock")
            }
        } preview: {
            // MARK: - Chart Preview
            DormChartPreview(dorm: dorm)
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
        .alert("取消定时查询", isPresented: $viewModel.isCancelScheduleAlertPresented) {
            Button("取消", role: .cancel) {}
            Button("确定", role: .destructive) { viewModel.removeSchedule(dorm) }
        } message: {
            Text("确定要取消定时查询吗？")
        }
        .sheet(isPresented: $viewModel.isShowNotificationSettings) {
            NotificationSettingsView(
                isPresented: $viewModel.isShowNotificationSettings,
                onConfirm: { hour, minute in
                    viewModel.handleNotificationSettings(dorm, scheduleHour: hour, scheduleMinute: minute)
                }
            )
        }
    }
}

// MARK: - 图表 Preview 组件
struct DormChartPreview: View {
    let dorm: Dorm

    var body: some View {
        let electricityValues = dorm.records?.map { $0.electricity } ?? []
        let minValue = electricityValues.min() ?? 0
        let maxValue = electricityValues.max() ?? 0
        let yMin = max(0, minValue - 5)
        let yMax = maxValue + 5

        VStack(alignment: .leading, spacing: 8) {
            // Header for Preview
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("宿舍号：\(dorm.room)")
                        .font(.headline)
                    if dorm.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }
                Text("\(dorm.campusName) · \(dorm.buildingName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()

            // Chart
            if let records = dorm.records, !records.isEmpty {
                Chart(records.sorted(by: { $0.date < $1.date })) { record in
                    LineMark(
                        x: .value("日期", record.date),
                        y: .value("电量", record.electricity)
                    )
                    .interpolationMethod(.catmullRom)
                    .symbol {
                        if records.count <= 1 {
                            Circle()
                                .frame(width: 8)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYScale(domain: yMin...yMax)
                .frame(width: 300, height: 200)
                .padding(8)
            } else {
                Text("暂无历史数据")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 300, height: 100)
            }
        }
    }
}
