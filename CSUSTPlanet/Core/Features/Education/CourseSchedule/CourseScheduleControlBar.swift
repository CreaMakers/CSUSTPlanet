//
//  CourseScheduleControlBar.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/6/18.
//

import SwiftUI

struct CourseScheduleControlBar: View {
    @Environment(\.courseScheduleLayoutConfig) private var layoutConfig

    let selectedSemester: String?
    let realCurrentWeek: Int?

    @Binding var currentWeek: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("今日 \(CourseScheduleUtil.dateFormatter.string(from: .now))")
                    .font(layoutConfig.isWideSize ? .title3 : .headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                if #unavailable(iOS 26.0) {
                    Text(selectedSemester ?? "默认学期")
                        .font(layoutConfig.isWideSize ? .subheadline : .caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Picker("选择周数", selection: $currentWeek.withAnimation()) {
                    ForEach(1...CourseScheduleUtil.weekCount, id: \.self) { week in
                        Text("第 \(week) 周").tag(week)
                    }
                }
                .fixedSize()

                Button(action: {
                    withAnimation {
                        if let realWeek = realCurrentWeek, realWeek > 0 && realWeek <= CourseScheduleUtil.weekCount {
                            self.currentWeek = realWeek
                        } else {
                            self.currentWeek = 1
                        }
                    }
                }) {
                    Text("本周").fontWeight(.medium)
                }
                .disabled(realCurrentWeek == nil || currentWeek == realCurrentWeek)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        #if os(iOS)
        .background(Color(PlatformColor.systemBackground))
        #endif
    }
}

#Preview("CourseScheduleConflictCard") {
    @Previewable @State var currentWeek = 8
    CourseScheduleControlBar(
        selectedSemester: "2024-2025-1",
        realCurrentWeek: 16,
        currentWeek: $currentWeek
    )
}
