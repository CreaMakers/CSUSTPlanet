//
//  DormScheduleConfigView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/25.
//

import SwiftUI

struct DormScheduleConfigView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedHour: Int
    @State private var selectedMinute: Int

    let onConfirm: (Int, Int) -> Void

    init(
        initialHour: Int = 20,
        initialMinute: Int = 0,
        onConfirm: @escaping (Int, Int) -> Void,
    ) {
        _selectedHour = State(initialValue: initialHour)
        _selectedMinute = State(initialValue: initialMinute)
        self.onConfirm = onConfirm
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("提醒时间") {
                    #if os(iOS)
                    HStack {
                        Picker("小时", selection: $selectedHour.withAnimation()) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(String(format: "%02d", hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()

                        Picker("分钟", selection: $selectedMinute.withAnimation()) {
                            ForEach(0..<60, id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                    }
                    .frame(height: 150)
                    #else
                    Picker("小时", selection: $selectedHour.withAnimation()) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(String(format: "%02d 时", hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("分钟", selection: $selectedMinute.withAnimation()) {
                        ForEach(0..<60, id: \.self) { minute in
                            Text(String(format: "%02d 分", minute)).tag(minute)
                        }
                    }
                    .pickerStyle(.menu)
                    #endif
                }

                Section {
                    Text("将在每天 \(formattedTime) 推送宿舍电量提醒。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
            }
            .formStyle(.grouped)
            .navigationTitle("定时提醒设置")
            .inlineToolbarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onConfirm(selectedHour, selectedMinute)
                        dismiss()
                    }
                }
            }
        }
    }

    private var formattedTime: String {
        String(format: "%02d:%02d", selectedHour, selectedMinute)
    }
}
