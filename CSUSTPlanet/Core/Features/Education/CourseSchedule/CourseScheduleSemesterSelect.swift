//
//  CourseScheduleSemesterSelect.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/6/18.
//

import SwiftUI

struct CourseScheduleSemesterSelect: View {
    @Binding var selectedSemester: String?
    let availableSemesters: [String]
    let isLoading: Bool

    let onRefresh: () async -> Void
    let onComplete: () async -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("学期选择") {
                    Picker("学期", selection: $selectedSemester) {
                        Text("默认学期").tag(nil as String?)
                        ForEach(availableSemesters, id: \.self) { semester in
                            Text(semester).tag(semester as String?)
                        }
                    }
                    #if os(iOS)
                    .pickerStyle(.wheel)
                    #elseif os(macOS)
                    .pickerStyle(.menu)
                    #endif
                }
                HStack {
                    Button(asyncAction: onRefresh) {
                        Text("刷新学期列表")
                    }
                    .disabled(isLoading)
                    if isLoading {
                        Spacer()
                        ProgressView().smallControlSizeOnMac()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("完成") {
                        dismiss()
                        await onComplete()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("学期选择")
            .inlineToolbarTitle()
        }
    }
}

#Preview("CourseScheduleSemesterSelect") {
    CourseScheduleSemesterSelect(
        selectedSemester: .constant(nil),
        availableSemesters: [],
        isLoading: false,
        onRefresh: {},
        onComplete: {}
    )
}
