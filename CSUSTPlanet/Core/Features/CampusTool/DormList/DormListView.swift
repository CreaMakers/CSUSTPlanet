//
//  DormListView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/21.
//

import SwiftUI

struct DormListView: View {
    @State var viewModel = DormListViewModel()
    @State private var scheduleConfigTargetDorm: DormGRDB?

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.dorms.isEmpty {
                ContentUnavailableView("暂无宿舍", systemImage: "building.2", description: Text("点击右上角添加宿舍"))
            } else {
                #if os(macOS)
                CustomScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.dorms) { dorm in
                            dormCard(dorm)
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 6)
                }
                #elseif os(iOS)
                List {
                    ForEach(viewModel.dorms) { dorm in
                        dormCard(dorm)
                            .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                #endif
            }
        }
        .task { await viewModel.loadInitial() }
        .navigationTitle("宿舍列表")
        .navigationSubtitleCompat("共\(viewModel.dorms.count)个宿舍")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { viewModel.isAddDormSheetPresented = true }) {
                    Label("添加宿舍", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.isAddDormSheetPresented) {
            AddDormView { room in
                viewModel.addDorm(room: room)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: scheduleConfigPresentedBinding) {
            if let dorm = scheduleConfigTargetDorm {
                DormScheduleConfigView(initialHour: dorm.scheduleHour ?? 20, initialMinute: dorm.scheduleMinute ?? 0) { hour, minute in
                    Task {
                        await viewModel.configureSchedule(for: dorm, hour: hour, minute: minute)
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
        .alert("通知权限被拒绝", isPresented: $viewModel.isNotificationDeniedAlertPresented) {
            Button(action: { viewModel.isNotificationDeniedAlertPresented = false }) {
                Text("取消")
            }
            Button(action: {
                NotificationManager.shared.openAppNotificationSettings()
                viewModel.isNotificationDeniedAlertPresented = false
            }) {
                Text("前往设置")
            }
        } message: {
            Text("需要开启通知权限以使用定时查询功能，请前往系统设置开启通知权限")
        }
        .alert(
            "删除宿舍",
            isPresented: .init(
                get: { viewModel.targetDeleteDorm != nil },
                set: { newValue in
                    if !newValue { viewModel.targetDeleteDorm = nil }
                }
            )
        ) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                guard let targetDeleteDorm = viewModel.targetDeleteDorm else { return }
                viewModel.deleteDorm(targetDeleteDorm)
                viewModel.targetDeleteDorm = nil
            }
        } message: {
            if let targetDeleteDorm = viewModel.targetDeleteDorm {
                Text("确定要删除 \(targetDeleteDorm.buildingName) \(targetDeleteDorm.room) 吗？")
            }
        }
        .errorToast($viewModel.errorToast)
    }

    // MARK: - Dorm Card

    @ViewBuilder
    private func dormCard(_ dorm: DormGRDB) -> some View {
        let electricityColor: Color = {
            guard let electricity = dorm.lastFetchElectricity else { return .secondary }
            return ColorUtil.electricityColor(electricity: electricity)
        }()

        Group {
            #if os(macOS)
            NavigationLink(value: AppRoute.features(.campusTool(.dormList(.detail(.main(dorm)))))) {
                CustomGroupBox {
                    dormCardContent(dorm, electricityColor: electricityColor)
                }
            }
            .buttonStyle(.plain)
            #elseif os(iOS)
            ZStack {
                NavigationLink(value: AppRoute.features(.campusTool(.dormList(.detail(.main(dorm)))))) {
                    EmptyView()
                }
                .opacity(0)

                CustomGroupBox {
                    dormCardContent(dorm, electricityColor: electricityColor)
                }
            }
            #endif
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(asyncAction: { await viewModel.queryElectricity(for: dorm) }) {
                Label("查询", systemImage: "bolt.fill")
            }
            .tint(.yellow)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(action: { viewModel.targetDeleteDorm = dorm }) {
                Label("删除", systemImage: "trash")
            }
            .tint(.red)
        }
        .contextMenu {
            Button(action: { viewModel.toggleFavorite(dorm) }) {
                Label(dorm.isFavorite ? "取消收藏" : "收藏宿舍", systemImage: dorm.isFavorite ? "star.slash" : "star")
            }

            Button(asyncAction: { await viewModel.queryElectricity(for: dorm) }) {
                Label("查询电量", systemImage: "bolt")
            }
            .disabled(viewModel.isQuerying(dorm))

            Menu {
                Button(action: {
                    guard viewModel.canConfigureSchedule(for: dorm) else { return }
                    scheduleConfigTargetDorm = dorm
                }) {
                    Label("配置定时通知任务", systemImage: "clock.badge")
                }
                .disabled(viewModel.isSchedulingDorm)

                Button(role: .destructive, action: { Task { await viewModel.cancelSchedule(for: dorm) } }) {
                    Label("取消定时通知任务", systemImage: "bell.slash")
                }
                .disabled(!dorm.scheduleEnabled || viewModel.isSchedulingDorm)
            } label: {
                Label("定时查询", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
            }

            Button(role: .destructive, action: { viewModel.targetDeleteDorm = dorm }) {
                Label("删除宿舍", systemImage: "trash")
            }
        }
    }

    // MARK: - Dorm Card Content

    @ViewBuilder
    private func dormCardContent(_ dorm: DormGRDB, electricityColor: Color) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 12) {
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
                        Image(systemName: "bell.badge.fill")
                            .font(.caption)
                            .foregroundStyle(.purple)
                    }
                }

                if let electricity = dorm.lastFetchElectricity {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(String(format: "%.2f", electricity))
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

                Text("\(dorm.campusName) · \(dorm.buildingName)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Button(asyncAction: { await viewModel.queryElectricity(for: dorm) }) {
                    if viewModel.isQuerying(dorm) {
                        ProgressView()
                            .smallControlSizeOnMac()
                            .frame(width: 15, height: 15)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.blue)
                            .frame(width: 15, height: 15)
                    }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isQuerying(dorm))

                Spacer()

                if let lastFetchDate = dorm.lastFetchDate {
                    VStack(alignment: .trailing, spacing: 2) {
                        LastUpdatedDateView(
                            lastUpdated: lastFetchDate,
                            font: .caption,
                            foregroundStyle: .tertiary
                        )

                        if let dormID = dorm.id, let info = viewModel.exhaustionInfoMap[dormID] {
                            Text(info)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
    }

    private var scheduleConfigPresentedBinding: Binding<Bool> {
        .init(
            get: { scheduleConfigTargetDorm != nil },
            set: { newValue in
                if !newValue { scheduleConfigTargetDorm = nil }
            }
        )
    }
}
