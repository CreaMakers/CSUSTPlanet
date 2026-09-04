//
//  ScheduleEvent.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/9/4.
//

import Foundation

/// 日程的业务类型
enum ScheduleEventKind: String, Codable, Hashable, Sendable {
    case course
    case exam
    case assignmentDeadline
    case electricityExhaustion
}

/// 日程的时间形态
enum ScheduleEventTiming: Codable, Hashable, Sendable {
    case interval(start: Date, end: Date)
    case point(at: Date)

    var anchorDate: Date {
        switch self {
        case .interval(let start, _):
            return start
        case .point(let at):
            return at
        }
    }
}

/// 日程详情中的一项标签和值
struct ScheduleEventDetail: Codable, Hashable, Sendable {
    let label: String
    let value: String
}

/// 日程的通用内容模型
struct ScheduleEventContent: Codable, Hashable, Sendable {
    let title: String
    let subtitle: String?
    let location: String?
    let details: [ScheduleEventDetail]
}

/// 日程页面使用的统一事件模型
struct ScheduleEvent: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let kind: ScheduleEventKind
    let timing: ScheduleEventTiming
    let content: ScheduleEventContent
}
