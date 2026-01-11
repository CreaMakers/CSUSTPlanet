//
//  DormHistoryView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/1/11.
//

import SwiftUI

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
        .trackView("DormHistory")
    }
}
