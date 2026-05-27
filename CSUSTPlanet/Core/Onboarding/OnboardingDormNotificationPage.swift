//
//  OnboardingDormNotificationPage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/31.
//

import SwiftUI

struct OnboardingDormNotificationPage: View {
    @Bindable var viewModel: DormListViewModel
    @State private var selectedDormID: Int64?
    @State private var isScheduleConfigPresented = false

    private var selectedDorm: DormGRDB? {
        if let selectedDormID {
            return viewModel.dorms.first(where: { $0.id == selectedDormID })
        }
        return viewModel.dorms.first(where: \.scheduleEnabled) ?? viewModel.dorms.first(where: \.isFavorite) ?? viewModel.dorms.first
    }

    private var isSelectedDormQuerying: Bool {
        guard let selectedDorm else { return false }
        return viewModel.isQuerying(selectedDorm)
    }

    private var onboardingTitle: String {
        if viewModel.dorms.isEmpty {
            return "配置宿舍通知"
        }
        return selectedDorm?.scheduleEnabled == true ? "定时通知已开启" : "配置宿舍通知"
    }

    private var onboardingDescription: String {
        if viewModel.dorms.isEmpty {
            return "先添加一个宿舍，之后就可以为宿舍配置电量定时提醒。"
        }
        if selectedDorm?.scheduleEnabled == true {
            return "当前宿舍已经完成定时通知配置，后续也可以随时调整提醒时间。"
        }
        return "选择一个宿舍，并为它设置每天的电量提醒时间。"
    }

    private var canConfigureSelectedDorm: Bool {
        guard let selectedDorm else { return false }
        return selectedDorm.hasFetchedElectricity && !isSelectedDormQuerying && !viewModel.isSchedulingDorm
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                headerSection
                primaryCard
                configureButtonSection

                if let selectedDorm, selectedDorm.scheduleEnabled {
                    scheduleSummaryCard(for: selectedDorm)
                }

                if let statusText {
                    footerStatusText(statusText)
                }

                footerText
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task { syncSelectedDorm(with: viewModel.dorms) }
        .onChange(of: viewModel.dorms) { _, newDorms in
            syncSelectedDorm(with: newDorms)
        }
        .sheet(isPresented: $viewModel.isAddDormSheetPresented) {
            AddDormView { room in
                viewModel.addDormAndQuery(room: room)
            }
        }
        .sheet(isPresented: $isScheduleConfigPresented) {
            if let selectedDorm {
                DormScheduleConfigView(initialHour: selectedDorm.scheduleHour ?? 20, initialMinute: selectedDorm.scheduleMinute ?? 0) { hour, minute in
                    Task {
                        await viewModel.configureSchedule(for: selectedDorm, hour: hour, minute: minute)
                    }
                }
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
        .errorToast($viewModel.errorToast)
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedDorm?.scheduleEnabled == true ? "bell.badge.fill" : "bell.badge")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(selectedDorm?.scheduleEnabled == true ? .green : .secondary)
                .padding(.top, 16)

            Text(onboardingTitle)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)

            Text(onboardingDescription)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var primaryCard: some View {
        if viewModel.isLoading {
            HStack(spacing: 12) {
                ProgressView()
                    .smallControlSizeOnMac()

                Text("正在读取宿舍信息...")
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.horizontal, 6)
        } else if viewModel.dorms.isEmpty {
            Button(action: { viewModel.isAddDormSheetPresented = true }) {
                Text("先添加宿舍")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 6)
        } else {
            CustomGroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    dormPickerContent
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 6)
        }
    }

    @ViewBuilder
    private var configureButtonSection: some View {
        if !viewModel.isLoading, !viewModel.dorms.isEmpty, selectedDorm?.scheduleEnabled != true {
            Button(action: handleConfigureButtonTapped) {
                if viewModel.isSchedulingDorm {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("配置宿舍电量通知")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canConfigureSelectedDorm)
            .padding(.horizontal, 6)
        }
    }

    @ViewBuilder
    private var dormPickerContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text("选择宿舍")
                    .font(.headline)

                Spacer()

                Picker("宿舍", selection: $selectedDormID) {
                    ForEach(viewModel.dorms) { dorm in
                        Text("\(dorm.buildingName) \(dorm.room)")
                            .tag(dorm.id as Int64?)
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
                .pickerStyle(.menu)
                .labelsHidden()
            }

            HStack(spacing: 12) {
                if let selectedDorm {
                    Button(asyncAction: { await viewModel.queryElectricity(for: selectedDorm) }) {
                        if viewModel.isQuerying(selectedDorm) {
                            ProgressView()
                                .smallControlSizeOnMac()
                        } else {
                            Text("刷新电量")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Spacer()

                currentElectricityValue
            }
        }
    }

    @ViewBuilder
    private var currentElectricityValue: some View {
        if let selectedDorm {
            if isSelectedDormQuerying {
                HStack(spacing: 6) {
                    ProgressView()
                        .smallControlSizeOnMac()

                    Text("查询中")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else if let electricity = selectedDorm.lastFetchElectricity {
                let electricityColor = ColorUtil.electricityColor(electricity: electricity)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(String(format: "%.2f", electricity))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(electricityColor)
                        .contentTransition(.numericText())

                    Text("kWh")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("暂无电量")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func scheduleSummaryCard(for dorm: DormGRDB) -> some View {
        CustomGroupBox {
            HStack(spacing: 14) {
                Circle()
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "clock.badge.checkmark.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(dorm.buildingName) \(dorm.room)")
                        .font(.headline)

                    Text("每天 \(formattedScheduleTime(for: dorm)) 提醒")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("宿舍定时通知已配置完成")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 6)
    }

    private var statusText: String? {
        guard !viewModel.dorms.isEmpty, selectedDorm?.scheduleEnabled != true else { return nil }

        if isSelectedDormQuerying {
            return "正在刷新该宿舍的电量数据，完成后即可继续配置定时通知。"
        }

        if let selectedDorm, !selectedDorm.hasFetchedElectricity {
            return "必须先查询到电量，才能进行定时通知配置。"
        }

        return nil
    }

    private func footerStatusText(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
    }

    private var footerText: some View {
        Text("您也可以稍后在“电量查询”页面继续调整提醒时间。")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
    }

    private func handleConfigureButtonTapped() {
        guard let selectedDorm else { return }

        guard selectedDorm.hasFetchedElectricity else {
            viewModel.errorToast.show(message: "请先成功查询一次宿舍电量后再配置定时通知")
            return
        }

        isScheduleConfigPresented = true
    }

    private func syncSelectedDorm(with dorms: [DormGRDB]) {
        if let selectedDormID, dorms.contains(where: { $0.id == selectedDormID }) {
            return
        }

        selectedDormID =
            dorms.first(where: \.scheduleEnabled)?.id
            ?? dorms.first(where: \.isFavorite)?.id
            ?? dorms.first?.id
    }

    private func formattedScheduleTime(for dorm: DormGRDB) -> String {
        String(format: "%02d:%02d", dorm.scheduleHour ?? 20, dorm.scheduleMinute ?? 0)
    }
}
