//
//  CourseStatusWidgetLiveActivity.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/15.
//

import ActivityKit
import CSUSTKit
import SwiftUI
import WidgetKit

struct CourseStatusWidgetAttributes: ActivityAttributes, Equatable {
    public struct ContentState: Codable, Hashable {}

    var courseName: String
    var teacher: String
    var classroom: String?

    var startDate: Date
    var endDate: Date
}

struct CourseStatusWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CourseStatusWidgetAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.teacher)
                        .font(.caption)
                        .padding(.top, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.classroom ?? "无教室")
                        .font(.caption)
                        .padding(.top, 4)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .center) {
                        if Date() < context.attributes.startDate {
                            Text("距离上课还有")
                                .font(.callout)
                            Text(timerInterval: Date()...context.attributes.startDate, countsDown: true)
                                .font(.title)
                                .fontWeight(.bold)
                                .lineLimit(1)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(.cyan)
                        } else if Date() >= context.attributes.startDate && Date() <= context.attributes.endDate {
                            Text("距离下课还有")
                                .font(.caption2)
                            Text(timerInterval: Date()...context.attributes.endDate, countsDown: true)
                                .font(.title)
                                .fontWeight(.bold)
                                .lineLimit(1)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(.cyan)
                        } else {
                            Text("已下课")
                                .font(.title)
                                .fontWeight(.bold)
                                .lineLimit(1)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(.green)
                        }

                        Text(context.attributes.courseName)
                            .font(.headline)
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        if Date() >= context.attributes.startDate && Date() <= context.attributes.endDate {
                            ProgressView(timerInterval: context.attributes.startDate...context.attributes.endDate, countsDown: false)
                                .progressViewStyle(.linear)
                                .tint(.cyan)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                if Date() < context.attributes.startDate {
                    Text("00:00")
                        .font(.caption2)
                        .hidden()
                        .overlay(alignment: .trailing) {
                            Text(timerInterval: Date()...context.attributes.startDate, countsDown: true)
                                .font(.caption2)
                                .monospacedDigit()
                        }
                } else if Date() >= context.attributes.startDate && Date() <= context.attributes.endDate {
                    let remainingTime = context.attributes.endDate.timeIntervalSince(Date())
                    let placeholder = remainingTime >= 3600 ? "00:00:00" : "00:00"

                    Text(placeholder)
                        .font(.caption2)
                        .hidden()
                        .overlay(alignment: .trailing) {
                            Text(timerInterval: Date()...context.attributes.endDate, countsDown: true)
                                .font(.caption2)
                                .monospacedDigit()
                        }
                } else {
                    Text("已下课")
                        .font(.caption2)
                }
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}

struct LockScreenView: View {
    let context: ActivityViewContext<CourseStatusWidgetAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(context.attributes.courseName)
                .font(.title2).bold()

            Divider()

            HStack {
                Label(context.attributes.teacher, systemImage: "person.fill")
                Spacer()
                Label(context.attributes.classroom ?? "无教室", systemImage: "location.fill")
            }
            .font(.subheadline)

            if Date() < context.attributes.startDate {
                VStack(alignment: .leading) {
                    Text("距离上课还有：")
                        .font(.caption)
                    Text(timerInterval: Date()...context.attributes.startDate, countsDown: true)
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(.cyan)
                }
                .padding(.top, 5)
            } else if Date() <= context.attributes.endDate {
                VStack(alignment: .leading) {
                    HStack {
                        Text("距离下课还有：")
                            .font(.caption)
                        Text(timerInterval: Date()...context.attributes.endDate)
                            .font(.caption)
                    }
                    ProgressView(timerInterval: context.attributes.startDate...context.attributes.endDate, countsDown: false)
                        .progressViewStyle(.linear)
                        .tint(.cyan)
                }
                .padding(.top, 5)
            } else {
                Label("已下课", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .activityBackgroundTint(.black.opacity(0.5))
    }
}

extension CourseStatusWidgetAttributes {
    static var preview: CourseStatusWidgetAttributes {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return .init(
            courseName: "程序设计、算法与数据结构（三）",
            teacher: "陈曦(小)副教授",
            classroom: "金12-106",
            startDate: dateFormatter.date(from: "2025-10-17 14:00")!,
            endDate: dateFormatter.date(from: "2025-10-17 15:40")!
        )
    }
}

#Preview("Notification", as: .content, using: CourseStatusWidgetAttributes.preview) {
    CourseStatusWidgetLiveActivity()
} contentStates: {
    CourseStatusWidgetAttributes.ContentState()
}
