//
//  OnboardingDormSetupPage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/31.
//

import CSUSTKit
import GRDB
import SwiftUI

struct OnboardingDormSetupPage: View {
    @Bindable var viewModel: DormListViewModel

    private var primaryDorm: DormGRDB? {
        viewModel.dorms.first(where: \.isFavorite) ?? viewModel.dorms.first
    }

    private var isPrimaryDormQuerying: Bool {
        guard let primaryDorm else { return false }
        return viewModel.isQuerying(primaryDorm)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                headerSection
                actionCard
                VStack(spacing: 12) {
                    dormCountText
                    footerText
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(isPresented: $viewModel.isAddDormSheetPresented) {
            AddDormView { room in
                viewModel.addDormAndQuery(room: room)
            }
        }
        .errorToast($viewModel.errorToast)
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: primaryDorm == nil ? "building.2.crop.circle" : "checkmark.circle.fill")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(primaryDorm == nil ? Color.secondary : .green)
                .padding(.top, 16)

            Text(primaryDorm == nil ? "添加您的宿舍" : "宿舍已添加")
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)

            Text(
                primaryDorm == nil
                    ? "绑定宿舍后，您可以查询宿舍电量，并继续配置后续的定时提醒。"
                    : "您已经完成宿舍添加，接下来可以继续配置宿舍定时通知。"
            )
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var actionCard: some View {
        if viewModel.isLoading {
            HStack(spacing: 12) {
                ProgressView()
                    .smallControlSizeOnMac()

                Text("正在读取宿舍信息...")
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.horizontal, 6)
        } else if let primaryDorm {
            CustomGroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    dormSummaryContent(for: primaryDorm)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 6)
        } else {
            Button(action: { viewModel.isAddDormSheetPresented = true }) {
                Text("添加宿舍")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 6)
        }
    }

    @ViewBuilder
    private var dormCountText: some View {
        if !viewModel.isLoading, primaryDorm != nil {
            Text("已添加 \(viewModel.dorms.count) 个宿舍")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
    }

    private var footerText: some View {
        Text("您也可以稍后在“电量查询”页面继续管理宿舍信息。")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
    }

    @ViewBuilder
    private func dormSummaryContent(for dorm: DormGRDB) -> some View {
        let electricityColor: Color = {
            guard let electricity = dorm.lastFetchElectricity else { return .secondary }
            return ColorUtil.electricityColor(electricity: electricity)
        }()

        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(dorm.buildingName) \(dorm.room)")
                    .font(.headline)

                Text(dorm.campusName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 4) {
                if isPrimaryDormQuerying {
                    ProgressView()
                        .smallControlSizeOnMac()

                    Text("查询中")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else if let electricity = dorm.lastFetchElectricity {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(String(format: "%.2f", electricity))
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(electricityColor)
                            .contentTransition(.numericText())

                        Text("kWh")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Text("当前电量")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("暂无数据")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

extension DormListViewModel {
    func addDormAndQuery(room: CampusCardHelper.Room) {
        guard let dorm = insertDormForOnboarding(room: room) else { return }

        Task {
            await queryElectricity(for: dorm)
        }
    }

    @discardableResult
    private func insertDormForOnboarding(room: CampusCardHelper.Room) -> DormGRDB? {
        guard let pool = DatabaseManager.shared.pool else { return nil }
        let building = room.building
        let campus = building.campus

        do {
            return try pool.write { db in
                let duplicated =
                    try DormGRDB
                    .filter(DormGRDB.Columns.room == room.name)
                    .filter(DormGRDB.Columns.buildingName == building.name)
                    .filter(DormGRDB.Columns.campusName == campus.rawValue)
                    .fetchOne(db) != nil
                if duplicated {
                    errorToast.show(message: "该宿舍信息已存在")
                    return nil
                }

                var dorm = DormGRDB(
                    id: nil,
                    room: room.name,
                    buildingName: building.name,
                    campusName: campus.rawValue,
                    isFavorite: false,
                    lastFetchDate: nil,
                    lastFetchElectricity: nil
                )
                try dorm.insert(db)

                if dorm.id != nil {
                    return dorm
                }

                return
                    try DormGRDB
                    .filter(DormGRDB.Columns.room == room.name)
                    .filter(DormGRDB.Columns.buildingName == building.name)
                    .filter(DormGRDB.Columns.campusName == campus.rawValue)
                    .order(DormGRDB.Columns.id.desc)
                    .fetchOne(db)
            }
        } catch {
            errorToast.show(message: error.localizedDescription)
            return nil
        }
    }
}
