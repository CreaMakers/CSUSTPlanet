//
//  ReminderOffsetSettingsView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/17.
//

import SwiftUI

struct ReminderOffsetSettingsView: View {
    @Binding var isPresented: Bool

    @State private var selectedHourOffset: Int = 2
    @State private var selectedMinuteOffset: Int = 0

    var onConfirm: (Int, Int) -> Void

    private let hours = Array(0...72)
    private let minutes = Array(0...59)

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("选择提醒时间")
                    .font(.headline)
                    .padding(.top, 20)

                HStack(spacing: 0) {
                    Picker("小时", selection: $selectedHourOffset) {
                        ForEach(hours, id: \.self) { hour in
                            Text("\(hour)小时").tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 120)
                    .clipped()

                    Picker("分钟", selection: $selectedMinuteOffset) {
                        ForEach(minutes, id: \.self) { minute in
                            Text("\(minute)分钟").tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 120)
                    .clipped()
                }
                .frame(height: 150)

                Text("提前 \(formatOffset()) 提醒")
                    .font(.title3)
                    .padding()

                VStack(alignment: .leading, spacing: 12) {
                    Text("作业提醒设置")
                        .font(.headline)
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            Text("•")
                            Text("系统将在作业截止时间前提醒您")
                        }

                        HStack(alignment: .top) {
                            Text("•")
                            Text("提醒将添加到系统提醒事项中")
                        }

                        HStack(alignment: .top) {
                            Text("•")
                            Text("只会添加未提交的作业")
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("作业提醒设置")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确认") {
                        isPresented = false
                        onConfirm(selectedHourOffset, selectedMinuteOffset)
                    }
                }
            }
        }
    }

    private func formatOffset() -> String {
        var components: [String] = []

        if selectedHourOffset > 0 {
            components.append("\(selectedHourOffset)小时")
        }

        if selectedMinuteOffset > 0 {
            components.append("\(selectedMinuteOffset)分钟")
        }

        if components.isEmpty {
            return "截止时间"
        }

        return components.joined(separator: " ")
    }
}

#Preview {
    NavigationStack {
        ReminderOffsetSettingsView(
            isPresented: .constant(true),
            onConfirm: { _, _ in }
        )
    }
}
