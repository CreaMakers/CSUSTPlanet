//
//  NotificationSettingsView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/17.
//

import SwiftUI

struct NotificationSettingsView: View {
    @Binding var isPresented: Bool

    @State private var selectedHour: Int = Calendar.current.component(.hour, from: .now)
    @State private var selectedMinute: Int = Calendar.current.component(.minute, from: .now)

    var onConfirm: (Int, Int) -> Void

    private let hours = Array(0...23)
    private let minutes = Array(0...59)

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("选择通知时间")
                    .font(.headline)
                    .padding(.top, 20)

                HStack(spacing: 0) {
                    Picker("小时", selection: $selectedHour) {
                        ForEach(hours, id: \.self) { hour in
                            Text("\(hour)时").tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 120)
                    .clipped()

                    Picker("分钟", selection: $selectedMinute) {
                        ForEach(minutes, id: \.self) { minute in
                            Text("\(minute)分").tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 120)
                    .clipped()
                }
                .frame(height: 150)

                Text("通知时间: \(String(format: "%02d:%02d", selectedHour, selectedMinute))")
                    .font(.title3)
                    .padding()

                VStack(alignment: .leading, spacing: 12) {
                    Text("宿舍电量查询提醒")
                        .font(.headline)
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            Text("•")
                            Text("系统将在您设置的时间自动查询宿舍剩余电量并推送")
                        }

                        HStack(alignment: .top) {
                            Text("•")
                            Text("查询结果将通过通知中心推送提醒")
                        }

                        HStack(alignment: .top) {
                            Text("•")
                            Text("每天只会在设定时间查询和通知一次")
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
            .navigationTitle("宿舍电量查询提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确认") {
                        isPresented = false
                        onConfirm(selectedHour, selectedMinute)
                    }
                }
            }
        }
        .trackView("NotificationSettings")
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView(
            isPresented: .constant(true),
            onConfirm: {
                _, _ in
            })
    }
}
