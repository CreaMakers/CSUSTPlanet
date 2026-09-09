//
//  ScheduleFilterView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/9/7.
//

import SwiftUI

struct ScheduleFilterView: View {
    @Binding var selectedEventKinds: Set<ScheduleEventKind>

    var body: some View {
        Form {
            Section("显示类型") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                    ForEach(ScheduleEventKind.allCases, id: \.self) { kind in
                        eventKindCell(kind)
                    }
                }
                .padding(.vertical, 4)
            }

            if selectedEventKinds != allEventKinds {
                Section {
                    Button("恢复全部") {
                        selectedEventKinds = allEventKinds
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("日程筛选")
        .inlineToolbarTitle()
    }

    private var allEventKinds: Set<ScheduleEventKind> {
        Set(ScheduleEventKind.allCases)
    }

    private func eventKindCell(_ kind: ScheduleEventKind) -> some View {
        let isSelected = selectedEventKinds.contains(kind)

        return Button {
            if isSelected {
                selectedEventKinds.remove(kind)
            } else {
                selectedEventKinds.insert(kind)
            }
        } label: {
            Text(kind.presentationTitle)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? kind.presentationTint.opacity(0.2)
                        : Color.gray.opacity(0.1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .foregroundStyle(isSelected ? kind.presentationTint : .primary)
        }
        .buttonStyle(.plain)
    }
}

#Preview("ScheduleFilterView") {
    NavigationStack {
        ScheduleFilterView(
            selectedEventKinds: .constant(Set(ScheduleEventKind.allCases))
        )
    }
}
