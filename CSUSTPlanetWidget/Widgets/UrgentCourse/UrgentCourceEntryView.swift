//
//  UrgentCourceEntryView.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/10/13.
//

import Foundation
import SwiftUI
import WidgetKit

struct UrgentCourseEntryView: View {
    var entry: UrgentCourseProvider.Entry

    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd HH:mm"
        return dateFormatter
    }()

    var body: some View {
        Group {
            if let data = entry.data, let lastUpdated = entry.lastUpdated {
                VStack {
                    HStack {
                        Text("待提交作业")
                            .font(.system(size: 14, weight: .bold))
                        if !data.courses.isEmpty {
                            Text("\(data.courses.count)")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(.red)
                        }
                        Spacer()
                        Button(intent: RefreshElectricityTimelineIntent()) {
                            Image(systemName: "arrow.clockwise.circle")
                        }
                        .foregroundStyle(.blue)
                        .buttonStyle(.plain)
                    }
                    Divider()
                    if data.courses.isEmpty {
                        Text("无待提交作业")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                        Spacer()
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(data.courses.prefix(4), id: \.id) { course in
                                Text(course.name)
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                            }
                        }
                        if data.courses.count > 4 {
                            Text("...")
                                .font(.system(size: 13, weight: .bold))
                        }
                        Spacer()
                        Text("更新时间: \(dateFormatter.string(from: lastUpdated))")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("请先在App内查询待提交作业")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .widgetURL(URL(string: "csustplanet://widget/urgentCourse"))
    }
}

#Preview(as: .systemSmall) {
    UrgentCourceWidget()
} timeline: {
    let intent = UrgentCourseIntent()
    mockUrgentCourseEntry(configuration: intent)
}
