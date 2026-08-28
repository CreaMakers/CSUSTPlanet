//
//  DormElectricityEntryView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/20.
//

import Charts
import SwiftUI
import WidgetKit

struct DormElectricityEntryView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily

    var entry: DormElectricityProvider.Entry

    // MARK: - Body

    var body: some View {
        Group {
            if let dorm = entry.configuration.dorm {
                VStack(spacing: 0) {
                    headerView(dorm: dorm, lastFetchDate: entry.lastFetchDate, lastFetchElectricity: entry.lastFetchElectricity)
                    if family == .systemSmall || (entry.lastFetchDate == nil && entry.lastFetchElectricity == nil) {
                        Divider().padding(.vertical, 4)
                    }
                    contentView(lastFetchDate: entry.lastFetchDate, lastFetchElectricity: entry.lastFetchElectricity, bounds: entry.bounds, records: entry.records)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                emptyView
            }
        }
        .widgetURL(entry.configuration.dorm?.dormID != nil ? URL(string: "csustplanet://features/electricity/\(entry.configuration.dorm?.dormID ?? 1)") : URL(string: "csustplanet://features/electricity"))
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Empty View

    var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "gearshape.fill")
                .font(.title)
                .foregroundStyle(.gray.opacity(0.8))
            VStack(spacing: 4) {
                Text("尚未选择宿舍")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("请长按当前小组件\n点击“编辑小组件”配置")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Header View

    func headerView(dorm: DormIntentEntity, lastFetchDate: Date?, lastFetchElectricity: Double?) -> some View {
        HStack(alignment: .center, spacing: 0) {
            if family == .systemSmall {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dorm.buildingName)
                        .font(.system(size: 14, weight: .medium))
                    Text(dorm.room)
                        .font(.system(size: 14, weight: .bold))
                }
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(dorm.campusName) \(dorm.buildingName)")
                        .font(.system(size: 14, weight: .medium))
                    Text(dorm.room)
                        .font(.system(size: 14, weight: .bold))
                }
                .layoutPriority(1)
                Spacer()
                if let lastFetchDate = lastFetchDate, let lastFetchElectricity = lastFetchElectricity {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.2f", lastFetchElectricity))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(ColorUtil.electricityColor(electricity: lastFetchElectricity))
                            + Text("度")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        LastUpdatedDateView(
                            lastUpdated: lastFetchDate,
                            font: .system(size: 10, weight: .medium),
                            foregroundStyle: .secondary
                        )
                        .multilineTextAlignment(.trailing)
                    }
                    .frame(alignment: .trailing)
                    .padding(.trailing, 8)
                }
            }
            Button(intent: RefreshElectricityTimelineIntent(dorm: dorm)) {
                Image(systemName: "arrow.clockwise.circle")
            }
            .foregroundColor(Color("AccentColor"))
            .buttonStyle(.plain)
        }
    }

    // MARK: - Content View

    @ViewBuilder
    func contentView(lastFetchDate: Date?, lastFetchElectricity: Double?, bounds: (min: Double, max: Double)?, records: [DormElectricityEntry.Record]) -> some View {
        if family == .systemSmall {
            if let lastFetchDate = lastFetchDate, let lastFetchElectricity = lastFetchElectricity {
                textView(lastFetchDate: lastFetchDate, lastFetchElectricity: lastFetchElectricity)
            } else {
                noDataView
            }
        } else {
            if let bounds = bounds {
                chartView(bounds: bounds, records: records)
                    .padding(.top, 8)
            } else {
                noDataView
            }
        }
    }

    // MARK: - Text View

    @ViewBuilder
    func textView(lastFetchDate: Date, lastFetchElectricity: Double) -> some View {
        VStack(alignment: .center, spacing: 0) {
            Spacer()
            Text("剩余电量")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Text(String(format: "%.2f", lastFetchElectricity))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(ColorUtil.electricityColor(electricity: lastFetchElectricity))
                + Text("度")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
            LastUpdatedDateView(
                lastUpdated: lastFetchDate,
                font: .system(size: 10, weight: .medium),
                foregroundStyle: .secondary
            )
            .multilineTextAlignment(.center)
        }
    }

    // MARK: - Chart View

    @ViewBuilder
    func chartView(bounds: (min: Double, max: Double), records: [DormElectricityEntry.Record]) -> some View {
        Chart(records) { record in
            LineMark(x: .value("日期", record.date), y: .value("电量", record.electricity))
                .interpolationMethod(.linear)
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
        .chartYScale(domain: (bounds.min - 1)...(bounds.max + 1))
    }

    // MARK: - No Data View

    var noDataView: some View {
        VStack(spacing: 8) {
            Image(systemName: "bolt.slash.fill")
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)
            Text("暂无电量数据")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}
