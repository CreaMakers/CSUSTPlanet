//
//  DormElectricityWidget.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/20.
//

import AppIntents
import CSUSTKit
import Charts
import OSLog
import SwiftData
import SwiftUI
import WidgetKit

struct DormElectricityProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> DormElectricityEntry {
        let intent = DormElectricityAppIntent()
        var dormitory = DormEntity(dorm: Dorm(room: "A544", building: CampusCardHelper.Building(name: "至诚轩5栋A区", id: "233", campus: .yuntang)))
        dormitory.records = [
            DormEntity.ElectricityRecord(electricity: 30, date: .now.addingTimeInterval(-86400)),
            DormEntity.ElectricityRecord(electricity: 20, date: .now.addingTimeInterval(-43200)),
            DormEntity.ElectricityRecord(electricity: 10, date: .now),
        ]
        intent.dormitory = dormitory

        return DormElectricityEntry(date: .now, configuration: intent)
    }

    func snapshot(for configuration: DormElectricityAppIntent, in context: Context) async -> DormElectricityEntry {
        return DormElectricityEntry(date: .now, configuration: configuration)
    }

    func timeline(for configuration: DormElectricityAppIntent, in context: Context) async -> Timeline<DormElectricityEntry> {
        Logger.dormElectricityWidget.info("DormElectricityProvider: 开始生成时间线")
        guard let selectedDormEntity = configuration.dormitory else {
            Logger.dormElectricityWidget.warning("DormElectricityProvider: 配置中未选择宿舍")
            let entry = DormElectricityEntry(date: .now, configuration: configuration)
            return Timeline(entries: [entry], policy: .never)
        }

        var finalDormEntity = selectedDormEntity

        do {
            let campus = CampusCardHelper.Campus(rawValue: selectedDormEntity.campusName)!
            let building = CampusCardHelper.Building(name: selectedDormEntity.buildingName, id: selectedDormEntity.buildingID, campus: campus)
            let room = selectedDormEntity.room

            let campusCardHelper = CampusCardHelper()
            let newElectricity = try await campusCardHelper.getElectricity(building: building, room: room)
            Logger.dormElectricityWidget.info("DormElectricityProvider: 电量获取成功: \(newElectricity)")

            let modelContext = SharedModel.context
            let dormID = selectedDormEntity.id

            let descriptor = FetchDescriptor<Dorm>(predicate: #Predicate<Dorm> { $0.id == dormID })

            if let dormToUpdate = try modelContext.fetch(descriptor).first {
                let record = ElectricityRecord(electricity: newElectricity, date: .now, dorm: dormToUpdate)
                modelContext.insert(record)
                try modelContext.save()
                finalDormEntity = DormEntity(dorm: dormToUpdate)
                Logger.dormElectricityWidget.info("DormElectricityProvider: 宿舍电量数据已更新")
            }
        } catch {
            Logger.dormElectricityWidget.error("DormElectricityProvider: 获取电量数据失败: \(error.localizedDescription)")
        }

        let updatedConfiguration = configuration
        updatedConfiguration.dormitory = finalDormEntity

        let entry = DormElectricityEntry(date: .now, configuration: updatedConfiguration)
        let nextUpdate = Date().addingTimeInterval(2 * 3600)  // 2 hours
        Logger.dormElectricityWidget.info("DormElectricityProvider: 下次更新计划于 \(nextUpdate)")
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

struct DormElectricityEntry: TimelineEntry {
    let date: Date
    let configuration: DormElectricityAppIntent
}

struct DormElectricityEntryView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily

    var entry: DormElectricityProvider.Entry

    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd HH:mm"
        return dateFormatter
    }()

    var body: some View {
        VStack(spacing: 4) {
            if let dormitory = entry.configuration.dormitory {
                VStack(spacing: 2) {
                    HStack {
                        if family == .systemSmall {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(dormitory.buildingName)
                                    .font(.system(size: 14, weight: .medium))
                                Text(dormitory.room)
                                    .font(.system(size: 14, weight: .bold))
                            }
                        } else if family == .systemMedium || family == .systemLarge {
                            Image(systemName: "bolt.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.yellow)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("\(dormitory.campusName)校区")
                                        .font(.system(size: 14, weight: .medium))
                                    Text(dormitory.buildingName)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                Text(dormitory.room)
                                    .font(.system(size: 14, weight: .bold))
                            }

                            if let last = dormitory.last {
                                Spacer()
                                VStack {
                                    Text(String(format: "%.2f", last.electricity))
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(ColorHelper.electricityColor(electricity: last.electricity))
                                        + Text("度")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)

                                    Text("\(dateFormatter.string(from: last.date))")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        Spacer()
                        Button(intent: RefreshElectricityTimelineIntent()) {
                            Image(systemName: "arrow.clockwise.circle")
                        }
                        .foregroundColor(.blue)
                        .buttonStyle(.plain)
                    }

                    Divider().padding(.vertical, 4)

                    Spacer()

                    if let last = dormitory.last {
                        if family == .systemSmall {
                            Text("剩余电量")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)

                            Text(String(format: "%.2f", last.electricity))
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(ColorHelper.electricityColor(electricity: last.electricity))
                                + Text("度")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)

                            Spacer()

                            Text("更新时间: \(dateFormatter.string(from: last.date))")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                        } else if family == .systemMedium || family == .systemLarge {
                            let electricityValues = dormitory.records.map { $0.electricity }
                            let minValue = electricityValues.min() ?? 0
                            let maxValue = electricityValues.max() ?? 0

                            let yMin = max(0, minValue - 5)
                            let yMax = maxValue + 5

                            Chart(dormitory.records.sorted { $0.date < $1.date }) { record in
                                LineMark(x: .value("日期", record.date), y: .value("电量", record.electricity))
                                    .interpolationMethod(.catmullRom)
                                    .symbol {
                                        if dormitory.records.count <= 1 {
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
                        }
                    } else {
                        Text("暂无数据")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                }
            } else {
                Text("请长按编辑小组件\n选择宿舍")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .widgetURL(URL(string: "csustplanet://widgets/electricity"))
    }
}

struct DormElectricityWidget: Widget {
    let kind = "DormElectricityWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: DormElectricityAppIntent.self, provider: DormElectricityProvider()) { entry in
            DormElectricityEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .modelContainer(SharedModel.container)
        }
        .configurationDisplayName("宿舍电量")
        .description("查询宿舍电量使用情况")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    DormElectricityWidget()
} timeline: {
    let intent = {
        let intent = DormElectricityAppIntent()
        var dormitory = DormEntity(dorm: Dorm(room: "A544", building: CampusCardHelper.Building(name: "至诚轩5栋A区", id: "233", campus: .yuntang)))
        dormitory.records = [
            DormEntity.ElectricityRecord(electricity: 30, date: .now.addingTimeInterval(-86400)),
            DormEntity.ElectricityRecord(electricity: 20, date: .now.addingTimeInterval(-43200)),
            DormEntity.ElectricityRecord(electricity: 10, date: .now),
        ]
        intent.dormitory = dormitory
        return intent
    }()
    DormElectricityEntry(date: .now, configuration: intent)
}

#Preview(as: .systemMedium) {
    DormElectricityWidget()
} timeline: {
    let intent = {
        let intent = DormElectricityAppIntent()
        var dormitory = DormEntity(dorm: Dorm(room: "A544", building: CampusCardHelper.Building(name: "至诚轩5栋A区", id: "233", campus: .yuntang)))
        dormitory.records = [
            DormEntity.ElectricityRecord(electricity: 30, date: .now.addingTimeInterval(-86400)),
            DormEntity.ElectricityRecord(electricity: 20, date: .now.addingTimeInterval(-43200)),
            DormEntity.ElectricityRecord(electricity: 10, date: .now),
        ]
        intent.dormitory = dormitory
        return intent
    }()
    DormElectricityEntry(date: .now, configuration: intent)
}
