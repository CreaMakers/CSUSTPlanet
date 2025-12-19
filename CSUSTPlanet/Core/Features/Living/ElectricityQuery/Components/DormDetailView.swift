//
//  DormDetailView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import Alamofire
import Charts
import Inject
import SwiftData
import SwiftUI

private enum ChartTimeRange: String, CaseIterable, Identifiable {
    case threeDays = "近3天"
    case oneWeek = "近1周"
    case twoWeeks = "近2周"
    case oneMonth = "近1月"
    case all = "全部"

    var id: String { self.rawValue }

    func startDate(from date: Date = Date()) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .threeDays: return calendar.date(byAdding: .day, value: -3, to: date)
        case .oneWeek: return calendar.date(byAdding: .day, value: -7, to: date)
        case .twoWeeks: return calendar.date(byAdding: .day, value: -14, to: date)
        case .oneMonth: return calendar.date(byAdding: .month, value: -1, to: date)
        case .all: return nil
        }
    }
}

struct DormDetailView: View {
    @ObserveInjection var inject
    @ObservedObject var viewModel: DormElectricityViewModel
    @Bindable var dorm: Dorm

    @State private var showDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ElectricityDashboardCard(
                    viewModel: viewModel,
                    records: dorm.records,
                    isLoading: viewModel.isQueryingElectricity
                )

                QuickActionsGrid(
                    dorm: dorm,
                    viewModel: viewModel
                )

                if let records = dorm.records, !records.isEmpty {
                    ElectricityTrendCard(records: records)
                }

                DormInfoCard(dorm: dorm)

                NavigationLink(destination: DormHistoryView(viewModel: viewModel, dorm: dorm)) {
                    HStack {
                        Label("查看所有历史记录", systemImage: "list.bullet.clipboard")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                if let records = dorm.records, !records.isEmpty {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Text("清除所有历史记录")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top, 10)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("宿舍详情")
        .navigationBarTitleDisplayMode(.inline)
        .alert("清除记录", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("确认清除", role: .destructive) {
                viewModel.deleteAllRecords(dorm)
            }
        } message: {
            Text("此操作将删除该宿舍所有的历史电量记录且无法恢复，确定要继续吗？")
        }
        .alert("取消定时查询", isPresented: $viewModel.isCancelScheduleAlertPresented) {
            Button("取消", role: .cancel) {}
            Button("确定", role: .destructive) { viewModel.removeSchedule(dorm) }
        } message: {
            Text("确定要取消定时查询吗？")
        }
        .enableInjection()
    }
}

struct ElectricityDashboardCard: View {
    @ObservedObject var viewModel: DormElectricityViewModel
    let records: [ElectricityRecord]?
    let isLoading: Bool

    private var record: ElectricityRecord? {
        records?.sorted(by: { $0.date > $1.date }).first
    }

    private var exhaustionInfo: String? {
        viewModel.getExhaustionInfo(from: records)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("剩余电量")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if let date = record?.date {
                    Text("更新于 " + date.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            ZStack {
                if let electricity = record?.electricity {
                    VStack {
                        HStack(alignment: .lastTextBaseline) {
                            Text(String(format: "%.2f", electricity))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(ColorUtil.electricityColor(electricity: electricity))

                            Text("kWh")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .fontWeight(.medium)
                                .padding(.bottom, 6)
                        }

                        if let info = exhaustionInfo {
                            Text(info)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("--.--")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.thinMaterial)
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct QuickActionsGrid: View {
    var dorm: Dorm
    @ObservedObject var viewModel: DormElectricityViewModel

    var body: some View {
        HStack(spacing: 12) {
            ActionButton(
                icon: viewModel.isQueryingElectricity ? "bolt.badge.clock" : "bolt.fill",
                title: viewModel.isQueryingElectricity ? "查询中..." : "刷新电量",
                titleColor: .white,
                iconColor: .white,
                backgroundColor: AnyShapeStyle(Color.blue.gradient)
            ) {
                viewModel.handleQueryElectricity(dorm)
            }
            .disabled(viewModel.isQueryingElectricity)

            ActionButton(
                icon: dorm.isFavorite ? "star.fill" : "star",
                title: dorm.isFavorite ? "已收藏" : "收藏",
                titleColor: .primary,
                iconColor: dorm.isFavorite ? .yellow : .primary,
                backgroundColor: AnyShapeStyle(Color(.secondarySystemGroupedBackground))
            ) {
                viewModel.toggleFavorite(dorm)
            }
            let scheduleTitle =
                dorm.scheduleEnabled
                ? String(format: "%02d:%02d时 提醒", dorm.scheduleHour ?? 0, dorm.scheduleMinute ?? 0)
                : "定时提醒"

            ActionButton(
                icon: dorm.scheduleEnabled ? "bell.fill" : "bell",
                title: scheduleTitle,
                titleColor: .primary,
                iconColor: dorm.scheduleEnabled ? .purple : .primary,
                backgroundColor: AnyShapeStyle(Color(.secondarySystemGroupedBackground))
            ) {
                if dorm.scheduleEnabled {
                    viewModel.isCancelScheduleAlertPresented = true
                } else {
                    viewModel.isShowNotificationSettings = true
                }
            }
            .disabled(viewModel.isScheduleLoading)
        }
    }

    private struct ActionButton<S: ShapeStyle>: View {
        let icon: String
        let title: String
        let titleColor: Color
        let iconColor: Color
        let backgroundColor: S
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                VStack(spacing: 6) {
                    Group {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(iconColor)
                    }
                    .frame(height: 28)

                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(titleColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

struct ElectricityTrendCard: View {
    let records: [ElectricityRecord]

    @State private var selectedRange: ChartTimeRange = .oneMonth
    @State private var displayData: [ElectricityRecord] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("电量趋势", systemImage: "chart.xyaxis.line")
                    .font(.headline)

                Spacer()

                Picker("时间范围", selection: $selectedRange) {
                    ForEach(ChartTimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .tint(.primary)
            }

            if displayData.isEmpty {
                ContentUnavailableView("该时段无数据", systemImage: "chart.bar.xaxis")
                    .frame(height: 200)
            } else {
                let yMin = (displayData.map(\.electricity).min() ?? 0) - 2
                let yMax = (displayData.map(\.electricity).max() ?? 0) + 2

                Chart(displayData) { record in
                    LineMark(
                        x: .value("日期", record.date),
                        y: .value("电量", record.electricity)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                    .symbol {
                        if displayData.count < 15 {
                            Circle()
                                .fill(.blue)
                                .frame(width: 8)
                        }
                    }
                }
                .chartYScale(domain: max(0, yMin)...yMax)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .frame(height: 220)
                .transaction { transaction in
                    transaction.animation = nil
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onChange(of: selectedRange, initial: true) { updateDisplayData() }
        .onChange(of: records) { updateDisplayData() }
    }

    private func updateDisplayData() {
        let sorted = records.sorted(by: { $0.date < $1.date })
        if let startDate = selectedRange.startDate() {
            self.displayData = sorted.filter { $0.date >= startDate }
        } else {
            self.displayData = sorted
        }
    }
}

struct DormInfoCard: View {
    let dorm: Dorm

    var body: some View {
        VStack(spacing: 0) {
            infoRow(icon: "house.fill", color: .blue, title: "宿舍", value: dorm.room)
            Divider().padding(.leading, 44)
            infoRow(icon: "building.2.fill", color: .green, title: "楼栋", value: dorm.buildingName)
            Divider().padding(.leading, 44)
            infoRow(icon: "map.fill", color: .orange, title: "校区", value: dorm.campusName)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func infoRow(icon: String, color: Color, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct DormHistoryView: View {
    @ObservedObject var viewModel: DormElectricityViewModel
    var dorm: Dorm

    var body: some View {
        List {
            if viewModel.sortedRecords.isEmpty {
                ContentUnavailableView("无历史记录", systemImage: "bolt.slash", description: Text("点击首页的刷新按钮获取最新电量"))
            } else {
                ForEach(viewModel.sortedRecords) { record in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(String(format: "%.2f", record.electricity)) kWh")
                                .font(.headline)
                                .monospacedDigit()
                                .foregroundStyle(ColorUtil.electricityColor(electricity: record.electricity))

                            Text(record.date.formatted(date: .numeric, time: .standard))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation {
                                viewModel.deleteRecord(record: record)
                            }
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("历史记录")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.updateSortedRecords(for: dorm) }
        .onChange(of: dorm.records) { viewModel.updateSortedRecords(for: dorm) }
    }
}
