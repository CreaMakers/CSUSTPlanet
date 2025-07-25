//
//  DormElectricityWidget.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/20.
//

import AppIntents
import Charts
import CSUSTKit
import SwiftData
import SwiftUI
import WidgetKit

struct DormElectricityProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> DormElectricityEntry {
        let intent = {
            let intent = DormElectricityAppIntent()
            intent.dormitory = DormEntity(dorm: Dorm(room: "A544", building: Building(name: "至诚轩5栋A区", id: "233", campus: .yuntang)))
            intent.dormitory!.records = [
                DormEntity.ElectricityRecord(electricity: 240, date: .now.addingTimeInterval(-86400)),
                DormEntity.ElectricityRecord(electricity: 233.33, date: .now.addingTimeInterval(-43200)),
                DormEntity.ElectricityRecord(electricity: 220.00, date: .now)
            ]
            return intent

        }()

        return DormElectricityEntry(date: .now, configuration: intent)
    }

    func snapshot(for configuration: DormElectricityAppIntent, in context: Context) async -> DormElectricityEntry {
        return DormElectricityEntry(date: .now, configuration: configuration)
    }

    func timeline(for configuration: DormElectricityAppIntent, in context: Context) async -> Timeline<DormElectricityEntry> {
        debugPrint("DormElectricityProvider: Starting timeline generation")
        guard let selectedDormEntity = configuration.dormitory else {
            debugPrint("DormElectricityProvider: No dormitory selected in configuration")
            let entry = DormElectricityEntry(date: .now, configuration: configuration)
            return Timeline(entries: [entry], policy: .never)
        }

        var finalDormEntity = selectedDormEntity

        do {
            let campus = Campus(rawValue: selectedDormEntity.campusName)!
            let building = Building(name: selectedDormEntity.buildingName, id: selectedDormEntity.buildingID, campus: campus)
            let room = selectedDormEntity.room

            let campusCardHelper = CampusCardHelper()
            let newElectricity = try await campusCardHelper.getElectricity(building: building, room: room)
            debugPrint("DormElectricityProvider: Electricity fetched successfully: \(newElectricity)")

            let modelContext = SharedModel.context
            let dormID = selectedDormEntity.id

            let descriptor = FetchDescriptor<Dorm>(predicate: #Predicate<Dorm> { $0.id == dormID })

            if let dormToUpdate = try modelContext.fetch(descriptor).first {
                let lastRecord = dormToUpdate.records?.sorted { $0.date > $1.date }.first

                if let lastRecord = lastRecord, lastRecord.electricity == newElectricity {
                    debugPrint("DormElectricityProvider: No update needed, electricity is the same as last record")
                } else {
                    let record = ElectricityRecord(electricity: newElectricity, date: .now, dorm: dormToUpdate)
                    modelContext.insert(record)
                    try modelContext.save()

                    finalDormEntity = DormEntity(dorm: dormToUpdate)
                    debugPrint("DormElectricityProvider: Dorm updated with new electricity data")
                }
            }

        } catch {
            debugPrint("DormElectricityProvider: Error fetching electricity data: \(error.localizedDescription)")
        }

        let updatedConfiguration = DormElectricityAppIntent()
        updatedConfiguration.dormitory = finalDormEntity

        let entry = DormElectricityEntry(date: .now, configuration: updatedConfiguration)
        let nextUpdate = Date().addingTimeInterval(2 * 3600) // 2 hours
        debugPrint("DormElectricityProvider: Next update scheduled for \(nextUpdate)")
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

                                    Text(dateFormatter.string(from: last.date))
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
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

                            Text(dateFormatter.string(from: last.date))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            Spacer()
                        } else if family == .systemMedium || family == .systemLarge {
                            Chart(dormitory.records.sorted { $0.date < $1.date }) { record in
                                LineMark(x: .value("日期", record.date), y: .value("电量", record.electricity))
                                    .interpolationMethod(.catmullRom)
                                    .symbol {
                                        Circle()
                                            .fill(Color.accentColor)
                                            .frame(width: 8)
                                    }
                            }
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                                    AxisValueLabel(format: .dateTime.month().day())
                                }
                            }
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
        intent.dormitory = DormEntity(dorm: Dorm(room: "A544", building: Building(name: "至诚轩5栋A区", id: "233", campus: .yuntang)))
        intent.dormitory!.records = [DormEntity.ElectricityRecord(electricity: 233.33, date: .now)]
        return intent
    }()
    DormElectricityEntry(date: .now, configuration: intent)
}

#Preview(as: .systemMedium) {
    DormElectricityWidget()
} timeline: {
    let intent = {
        let intent = DormElectricityAppIntent()
        intent.dormitory = DormEntity(dorm: Dorm(room: "A544", building: Building(name: "至诚轩5栋A区", id: "233", campus: .yuntang)))
        intent.dormitory!.records = [
            DormEntity.ElectricityRecord(electricity: 233.33, date: .now),
            DormEntity.ElectricityRecord(electricity: 220.00, date: Date().addingTimeInterval(-86400)),
            DormEntity.ElectricityRecord(electricity: 210.50, date: Date().addingTimeInterval(-172800)),
            DormEntity.ElectricityRecord(electricity: 200.75, date: Date().addingTimeInterval(-259200))
        ]
        return intent
    }()
    DormElectricityEntry(date: .now, configuration: intent)
}
