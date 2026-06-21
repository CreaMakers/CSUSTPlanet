//
//  MoocCoursesPreviewData.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/21.
//

import CSUSTKit
import Foundation

enum MoocCoursesPreviewData {
    static let referenceDate = Date.now

    static let mobileDevelopmentCourse = MoocHelper.Course(
        id: "10001",
        name: "移动应用开发",
        number: "CS101",
        department: "计算机与通信工程学院",
        teacher: "张老师"
    )

    static let softwareEngineeringCourse = MoocHelper.Course(
        id: "10002",
        name: "软件工程实践",
        number: "CS202",
        department: "计算机与通信工程学院",
        teacher: "李老师"
    )

    static let generalEducationCourse = MoocHelper.Course(
        id: "10003",
        name: "大学生创新创业基础",
        number: nil,
        department: "创新创业学院",
        teacher: nil
    )

    static let courses = [
        mobileDevelopmentCourse,
        softwareEngineeringCourse,
        generalEducationCourse,
    ]

    static let unsubmittedAssignment = makeAssignment(
        id: 1,
        title: "SwiftUI 列表与状态管理实验报告",
        publisher: "张老师",
        canSubmit: true,
        submitStatus: false,
        deadlineOffset: 2 * 24 * 60 * 60,
        startOffset: -3 * 24 * 60 * 60
    )

    static let submittedAssignment = makeAssignment(
        id: 2,
        title: "课程页面阅读记录",
        publisher: "张老师",
        canSubmit: true,
        submitStatus: true,
        deadlineOffset: 5 * 24 * 60 * 60,
        startOffset: -24 * 60 * 60
    )

    static let expiredAssignment = makeAssignment(
        id: 3,
        title: "MOOC 单元测验复盘",
        publisher: "李老师",
        canSubmit: false,
        submitStatus: false,
        deadlineOffset: -24 * 60 * 60,
        startOffset: -7 * 24 * 60 * 60
    )

    static let assignments = [
        unsubmittedAssignment,
        submittedAssignment,
        expiredAssignment,
    ]

    static func makeAssignment(
        id: Int,
        title: String,
        publisher: String,
        canSubmit: Bool,
        submitStatus: Bool,
        deadlineOffset: TimeInterval,
        startOffset: TimeInterval
    ) -> MoocHelper.Assignment {
        MoocHelper.Assignment(
            id: id,
            title: title,
            publisher: publisher,
            canSubmit: canSubmit,
            submitStatus: submitStatus,
            deadline: referenceDate.addingTimeInterval(deadlineOffset),
            startTime: referenceDate.addingTimeInterval(startOffset)
        )
    }
}
