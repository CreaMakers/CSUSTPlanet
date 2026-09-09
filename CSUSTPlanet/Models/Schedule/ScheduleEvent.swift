//
//  ScheduleEvent.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/9/4.
//

import Foundation
import SwiftUI

/// 日程的业务类型
enum ScheduleEventKind: String, Codable, Hashable, Sendable, CaseIterable {
    case course
    case exam
    case assignment
    case electricity

    var presentationTitle: String {
        switch self {
        case .course:
            return "课程"
        case .exam:
            return "考试"
        case .assignment:
            return "作业"
        case .electricity:
            return "电量"
        }
    }

    var presentationTint: Color {
        switch self {
        case .course:
            return .blue
        case .exam:
            return .orange
        case .assignment:
            return .purple
        case .electricity:
            return .green
        }
    }

    var presentationSortPriority: Int {
        switch self {
        case .course:
            return 0
        case .exam:
            return 1
        case .assignment:
            return 2
        case .electricity:
            return 3
        }
    }
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
