//
//  CourseScheduleWeeksSelectionSheet.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/8/2.
//

import SwiftUI

/// 周次选择 Sheet：快捷「全部/单周/双周」+ 自定义网格多选
struct CourseScheduleWeeksSelectionSheet: View {
    @Binding var selectedWeeks: [Int]
    let weekCount: Int

    @Environment(\.dismiss) private var dismiss

    @State private var weeksCopy: [Int] = []

    var body: some View {
        NavigationStack {
            List {
                Section("快捷选择") {
                    Button("全部") {
                        weeksCopy = Array(1...weekCount)
                    }
                    Button("单周") {
                        weeksCopy = Array(stride(from: 1, through: weekCount, by: 2))
                    }
                    Button("双周") {
                        weeksCopy = Array(stride(from: 2, through: weekCount, by: 2))
                    }
                }
                Section("自定义") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                        ForEach(1...weekCount, id: \.self) { week in
                            weekCell(week)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("选择周次")
            .inlineToolbarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("完成") {
                        selectedWeeks = weeksCopy
                        dismiss()
                    }
                }
            }
            .onAppear {
                weeksCopy = selectedWeeks
            }
        }
    }

    // MARK: - Helpers

    private func weekCell(_ week: Int) -> some View {
        let isSelected = weeksCopy.contains(week)
        return Button {
            if isSelected {
                weeksCopy.removeAll { $0 == week }
            } else {
                weeksCopy.append(week)
            }
        } label: {
            Text("\(week)")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .foregroundStyle(isSelected ? Color.accentColor : .primary)
        }
        .buttonStyle(.plain)
    }
}
