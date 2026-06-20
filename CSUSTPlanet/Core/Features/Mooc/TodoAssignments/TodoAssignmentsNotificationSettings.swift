//
//  TodoAssignmentsNotificationSettings.swift
//  CSUSTPlanet
//
//  Created by OpenCode on 2026/4/4.
//

import SwiftUI

struct TodoAssignmentsNotificationSettings: View {
    let onCancel: () -> Void
    let onSave: (Bool, Int, Int) async -> Void

    @State private var enabled: Bool
    @State private var selectedHour: Int
    @State private var selectedMinute: Int

    init(
        isEnabled: Bool,
        reminderOffsetHour: Int,
        reminderOffsetMinute: Int,
        onCancel: @escaping () -> Void,
        onSave: @escaping (Bool, Int, Int) async -> Void
    ) {
        self.onCancel = onCancel
        self.onSave = onSave
        _enabled = State(initialValue: isEnabled)
        _selectedHour = State(initialValue: reminderOffsetHour)
        _selectedMinute = State(initialValue: reminderOffsetMinute)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("开启作业提醒", isOn: $enabled.withAnimation())
                } header: {
                    Text("提醒开关")
                } footer: {
                    Text("开启后，系统会在作业截止前按你设置的时间发送本地通知提醒。")
                }

                Section("提前时间") {
                    #if os(iOS)
                    HStack {
                        Picker("小时", selection: $selectedHour.withAnimation()) {
                            ForEach(0...72, id: \.self) { hour in
                                Text("\(hour)小时").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()

                        Picker("分钟", selection: $selectedMinute.withAnimation()) {
                            ForEach(0...59, id: \.self) { minute in
                                Text("\(minute)分钟").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                    }
                    .frame(height: 150)
                    #else
                    Picker("小时", selection: $selectedHour.withAnimation()) {
                        ForEach(0...72, id: \.self) { hour in
                            Text("\(hour) 小时").tag(hour)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("分钟", selection: $selectedMinute.withAnimation()) {
                        ForEach(0...59, id: \.self) { minute in
                            Text("\(minute) 分钟").tag(minute)
                        }
                    }
                    .pickerStyle(.menu)
                    #endif
                }

                Section {
                    LabeledContent("提醒预览") {
                        Text(previewText)
                    }
                    .contentTransition(.numericText())
                }
            }
            .formStyle(.grouped)
            .navigationTitle("作业提醒设置")
            .inlineToolbarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(
                        "保存",
                        asyncAction: {
                            await onSave(enabled, selectedHour, selectedMinute)
                        })
                }
            }
        }
    }

    private var previewText: String {
        if selectedHour == 0 && selectedMinute == 0 {
            return "在截止时提醒"
        }

        var components: [String] = []
        if selectedHour > 0 {
            components.append("\(selectedHour)小时")
        }
        if selectedMinute > 0 {
            components.append("\(selectedMinute)分钟")
        }
        return "提前 \(components.joined(separator: " ")) 提醒"
    }

}

#Preview("TodoAssignmentsNotificationSettings") {
    TodoAssignmentsNotificationSettings(
        isEnabled: true,
        reminderOffsetHour: 2,
        reminderOffsetMinute: 30,
        onCancel: {},
        onSave: { _, _, _ in }
    )
}
