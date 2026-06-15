//
//  DormDetailView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/21.
//

import Charts
import SwiftUI

struct DormDetailView: View {
    @State private var viewModel: DormDetailViewModel

    init(dorm: DormGRDB) {
        _viewModel = State(initialValue: DormDetailViewModel(dorm: dorm))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                electricityDashboardCard
                quickActionsGrid

                if !viewModel.sortedRecords.isEmpty {
                    electricityTrendCard
                }

                dormInfoCard
                historyEntryButton

                if !viewModel.sortedRecords.isEmpty {
                    clearHistoryButton
                }
            }
            .padding()
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .task { await viewModel.loadInitial() }
        .navigationTitle("宿舍详情")
        .navigationSubtitleCompat("\(viewModel.dorm.buildingName) \(viewModel.dorm.room)")
        .alert("清除记录", isPresented: $viewModel.isDeleteAllRecordsAlertPresented) {
            Button("取消", role: .cancel) {}
            Button("确认清除", role: .destructive) {
                withAnimation {
                    viewModel.deleteAllRecords()
                }
            }
        } message: {
            Text("此操作将删除该宿舍所有的历史电量记录且无法恢复，确定要继续吗？")
        }
        .alert("取消定时任务", isPresented: $viewModel.isCancelScheduleAlertPresented) {
            Button("保留", role: .cancel) {}
            Button("取消定时任务", role: .destructive) {
                Task { await viewModel.cancelSchedule() }
            }
            .disabled(viewModel.isSchedulingDorm)
        } message: {
            Text("确认取消每天 \(scheduleTimeText) 的宿舍电量提醒吗？")
        }
        .alert("通知权限被拒绝", isPresented: $viewModel.isNotificationDeniedAlertPresented) {
            Button("取消", role: .cancel) {
                viewModel.isNotificationDeniedAlertPresented = false
            }
            Button("前往设置") {
                NotificationManager.shared.openAppNotificationSettings()
                viewModel.isNotificationDeniedAlertPresented = false
            }
        } message: {
            Text("需要开启通知权限以使用定时查询功能，请前往系统设置开启通知权限")
        }
        .sheet(isPresented: $viewModel.isScheduleConfigSheetPresented) {
            DormScheduleConfigView(initialHour: viewModel.dorm.scheduleHour ?? 20, initialMinute: viewModel.dorm.scheduleMinute ?? 0) { hour, minute in
                Task {
                    await viewModel.configureSchedule(hour: hour, minute: minute)
                }
            }
            .presentationDetents([.medium, .large])
        }
        .errorToast($viewModel.errorToast)
    }

    @ViewBuilder
    private var electricityDashboardCard: some View {
        CustomGroupBox {
            VStack(spacing: 12) {
                HStack {
                    Text("剩余电量")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let lastFetchDate = viewModel.dorm.lastFetchDate {
                        LastUpdatedDateView(
                            lastUpdated: lastFetchDate,
                            font: .caption,
                            foregroundStyle: .tertiary
                        )
                        .contentTransition(.numericText())
                    }
                }

                if let electricity = viewModel.dorm.lastFetchElectricity {
                    VStack {
                        HStack(alignment: .lastTextBaseline) {
                            Text(String(format: "%.2f", electricity))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(ColorUtil.electricityColor(electricity: electricity))
                                .contentTransition(.numericText())

                            Text("kWh")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .fontWeight(.medium)
                                .padding(.bottom, 6)
                        }

                        if let info = viewModel.exhaustionInfo {
                            Text(info)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("--.--")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
            }
        }
        .animation(.snappy, value: viewModel.dorm.lastFetchElectricity)
        .animation(.snappy, value: viewModel.dorm.lastFetchDate)
    }

    @ViewBuilder
    private var quickActionsGrid: some View {
        HStack(spacing: 12) {
            actionButton(
                icon: viewModel.isQueryingElectricity ? "bolt.badge.clock" : "bolt.fill",
                title: viewModel.isQueryingElectricity ? "查询中..." : "刷新电量",
                titleColor: .white,
                iconColor: .white,
                backgroundColor: AnyShapeStyle(Color.blue.gradient),
                asyncAction: { await viewModel.queryElectricity() }
            )
            .disabled(viewModel.isQueryingElectricity)

            actionButton(
                icon: viewModel.dorm.isFavorite ? "star.fill" : "star",
                title: viewModel.dorm.isFavorite ? "已收藏" : "收藏",
                titleColor: .primary,
                iconColor: viewModel.dorm.isFavorite ? .yellow : .primary,
                asyncAction: { viewModel.toggleFavorite() }
            )
            .symbolEffect(.bounce.byLayer, value: viewModel.dorm.isFavorite)

            actionButton(
                icon: viewModel.dorm.scheduleEnabled ? "bell.badge.fill" : "bell",
                title: viewModel.dorm.scheduleEnabled ? "定时 \(scheduleTimeText)" : "定时查询",
                titleColor: .primary,
                iconColor: viewModel.dorm.scheduleEnabled ? .purple : .primary,
                asyncAction: {
                    if viewModel.dorm.scheduleEnabled {
                        viewModel.isCancelScheduleAlertPresented = true
                    } else {
                        guard viewModel.canConfigureSchedule() else { return }
                        viewModel.isScheduleConfigSheetPresented = true
                    }
                }
            )
            .disabled(viewModel.isSchedulingDorm)
        }
    }

    @ViewBuilder
    private func actionButton(
        icon: String,
        title: String,
        titleColor: Color,
        iconColor: Color,
        backgroundColor: AnyShapeStyle? = nil,
        asyncAction: @escaping () async -> Void
    ) -> some View {
        Button(asyncAction: asyncAction) {
            if let backgroundColor {
                actionButtonContent(icon: icon, title: title, titleColor: titleColor, iconColor: iconColor)
                    .frame(maxHeight: .infinity)
                    .background(RoundedRectangle(cornerRadius: 15).fill(backgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            } else {
                CustomGroupBox {
                    actionButtonContent(icon: icon, title: title, titleColor: titleColor, iconColor: iconColor)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .frame(height: 80)
    }

    @ViewBuilder
    private func actionButtonContent(icon: String, title: String, titleColor: Color, iconColor: Color) -> some View {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var dormInfoCard: some View {
        CustomGroupBox {
            VStack(spacing: 12) {
                infoRow(icon: "house.fill", color: .blue, title: "宿舍", value: viewModel.dorm.room)
                infoRow(icon: "building.2.fill", color: .green, title: "楼栋", value: viewModel.dorm.buildingName)
                infoRow(icon: "map.fill", color: .orange, title: "校区", value: viewModel.dorm.campusName)
            }
        }
    }

    @ViewBuilder
    private var electricityTrendCard: some View {
        CustomGroupBox {
            VStack(alignment: .leading, spacing: 16) {
                Label("近三个月电量趋势", systemImage: "chart.xyaxis.line")
                    .font(.headline)

                Chart(viewModel.chartRecords) { record in
                    LineMark(
                        x: .value("日期", record.date),
                        y: .value("电量", record.electricity)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.linear)
                    .symbol {
                        if viewModel.chartRecords.count < 15 {
                            Circle()
                                .fill(.blue)
                                .frame(width: 8)
                        }
                    }
                }
                .chartYScale(domain: viewModel.chartYDomain)
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
    }

    @ViewBuilder
    private var historyEntryButton: some View {
        NavigationLink(value: AppRoute.features(.campusTool(.dormList(.detail(.history(viewModel)))))) {
            CustomGroupBox {
                HStack {
                    Label("查看近三个月历史记录", systemImage: "list.bullet.clipboard")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var clearHistoryButton: some View {
        Button(role: .destructive) {
            viewModel.isDeleteAllRecordsAlertPresented = true
        } label: {
            Text("清除所有历史记录")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(.top, 10)
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
    }

    private var scheduleTimeText: String {
        guard let hour = viewModel.dorm.scheduleHour, let minute = viewModel.dorm.scheduleMinute else {
            return "--:--"
        }
        return String(format: "%02d:%02d", hour, minute)
    }
}
