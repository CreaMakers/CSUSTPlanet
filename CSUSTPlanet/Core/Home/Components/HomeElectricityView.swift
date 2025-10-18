//
//  HomeElectricityView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import SwiftUI

struct HomeElectricityView: View {
    let electricityDorms: [Dorm]

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            NavigationLink(destination: ElectricityQueryView()) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.yellow)

                        Text("电量查询")
                            .foregroundColor(.primary)
                    }
                    .font(.headline)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            Divider()

            // 内容
            if !electricityDorms.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(electricityDorms.enumerated()), id: \.offset) { index, dorm in
                        electricityCard(dorm: dorm)

                        if index < electricityDorms.count - 1 {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.vertical, 12)

            } else {
                emptyStateView(
                    icon: "bolt.fill",
                    title: "暂无宿舍信息",
                    description: "请先添加宿舍信息"
                )
                .padding(.vertical, 20)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func electricityCard(dorm: Dorm) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dorm.buildingName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text("宿舍 \(dorm.room)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let record = dorm.lastRecord {
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(String(format: "%.2f", record.electricity))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(ColorHelper.electricityColor(electricity: record.electricity))

                        Text("kWh")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Text(formatElectricityDate(record.date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("暂无记录")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func formatElectricityDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }

    private func emptyStateView(icon: String, title: String, description: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.secondary)

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeElectricityView(electricityDorms: [])
}
