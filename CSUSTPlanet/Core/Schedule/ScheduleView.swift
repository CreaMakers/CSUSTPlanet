//
//  ScheduleView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/9/3.
//

import SwiftUI

struct ScheduleView: View {
    @State private var events: [ScheduleEvent] = []

    var body: some View {
        ScheduleContent(events: events)
            .onReceive(ScheduleEventStore.shared.eventsPublisher.receive(on: RunLoop.main)) { events in
                self.events = events
            }
    }
}

enum SchedulePreviewData {
    static let referenceDate: Date = {
        ScheduleDateUtil.calendar.date(
            from: DateComponents(year: 2026, month: 9, day: 4, hour: 12)
        )!
    }()

    static let events: [ScheduleEvent] = [
        ScheduleEvent(
            id: "preview-course",
            kind: .course,
            timing: .interval(
                start: date(dayOffset: 0, hour: 8, minute: 0),
                end: date(dayOffset: 0, hour: 9, minute: 40)
            ),
            content: ScheduleEventContent(
                title: "软件工程",
                subtitle: "张老师",
                location: "教学楼 A101",
                details: [
                    ScheduleEventDetail(label: "周次", value: "第 3 周"),
                    ScheduleEventDetail(label: "节次", value: "第 1-2 节"),
                ]
            )
        ),
        ScheduleEvent(
            id: "preview-exam",
            kind: .exam,
            timing: .interval(
                start: date(dayOffset: 0, hour: 14, minute: 0),
                end: date(dayOffset: 0, hour: 16, minute: 0)
            ),
            content: ScheduleEventContent(
                title: "考试：数据库原理",
                subtitle: "李老师",
                location: "实验楼 B203",
                details: [
                    ScheduleEventDetail(label: "座位号", value: "B203-18"),
                    ScheduleEventDetail(label: "校区", value: "云塘校区"),
                ]
            )
        ),
        ScheduleEvent(
            id: "preview-assignment",
            kind: .assignment,
            timing: .point(at: date(dayOffset: 0, hour: 23, minute: 30)),
            content: ScheduleEventContent(
                title: "提交第三章课后作业",
                subtitle: "网络课程中心 · 软件工程",
                location: nil,
                details: [
                    ScheduleEventDetail(label: "状态", value: "待提交"),
                    ScheduleEventDetail(label: "发布人", value: "课程助教"),
                ]
            )
        ),
        ScheduleEvent(
            id: "preview-electricity",
            kind: .electricity,
            timing: .point(at: date(dayOffset: 1, hour: 18, minute: 20)),
            content: ScheduleEventContent(
                title: "电量预计耗尽",
                subtitle: "云塘校区 · 15栋 · 302",
                location: nil,
                details: [
                    ScheduleEventDetail(label: "当前电量", value: "6.80 度"),
                    ScheduleEventDetail(label: "最近更新", value: "9月4日 10:20"),
                ]
            )
        ),
        ScheduleEvent(
            id: "preview-past-course",
            kind: .course,
            timing: .interval(
                start: date(dayOffset: -2, hour: 19, minute: 30),
                end: date(dayOffset: -2, hour: 21, minute: 10)
            ),
            content: ScheduleEventContent(
                title: "大学物理",
                subtitle: "王老师",
                location: "实验楼 C302",
                details: []
            )
        ),
    ]

    private static func date(dayOffset: Int, hour: Int, minute: Int) -> Date {
        let day = ScheduleDateUtil.calendar.date(
            byAdding: .day,
            value: dayOffset,
            to: ScheduleDateUtil.startOfDay(for: referenceDate)
        )!
        return ScheduleDateUtil.calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
    }
}

#Preview("ScheduleView") {
    NavigationStack {
        ScheduleContent(
            events: SchedulePreviewData.events,
            referenceDate: SchedulePreviewData.referenceDate
        )
    }
}
