//
//  ScheduleCurrentTimeIndicator.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/9/7.
//

import SwiftUI

struct ScheduleCurrentTimeIndicator: View {
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)

            RoundedRectangle(cornerRadius: 1)
                .fill(Color.red)
                .frame(maxWidth: .infinity)
                .frame(height: 2)
        }
        .frame(maxWidth: .infinity, minHeight: 8, maxHeight: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("当前时间")
    }
}

#Preview("ScheduleCurrentTimeIndicator") {
    ScheduleCurrentTimeIndicator()
        .padding()
}
