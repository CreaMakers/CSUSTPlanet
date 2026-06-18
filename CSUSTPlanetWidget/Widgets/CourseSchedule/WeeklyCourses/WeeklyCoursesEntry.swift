//
//  WeeklyCoursesEntry.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/25.
//

import CSUSTKit
import WidgetKit

private let courses = [
    EduHelper.Course(
        courseName: "软件工程概论",
        groupName: nil,
        teacher: "胡立辉高级实验师",
        sessions: [
            EduHelper.ScheduleSession(weeks: [3], startSection: 3, endSection: 4, dayOfWeek: EduHelper.DayOfWeek.thursday, classroom: "金6-102"),
            EduHelper.ScheduleSession(weeks: [3], startSection: 7, endSection: 8, dayOfWeek: EduHelper.DayOfWeek.monday, classroom: "金12-205"),
        ]
    ),
    EduHelper.Course(
        courseName: "体育(三)",
        groupName: "(24计算机跆拳道男11)",
        teacher: "余新畅无",
        sessions: [
            EduHelper.ScheduleSession(weeks: [3], startSection: 3, endSection: 4, dayOfWeek: EduHelper.DayOfWeek.monday, classroom: "金西田径场1")
        ]
    ),
    EduHelper.Course(
        courseName: "美术鉴赏(艺术及其他)",
        groupName: nil,
        teacher: "赵晖(14)讲师",
        sessions: [
            EduHelper.ScheduleSession(weeks: [3], startSection: 9, endSection: 10, dayOfWeek: EduHelper.DayOfWeek.wednesday, classroom: "金12-215")
        ]
    ),
    EduHelper.Course(
        courseName: "无人机设计与空天科技导论（自然科学）",
        groupName: nil,
        teacher: "张云菲副教授,陈良宇讲师",
        sessions: [
            EduHelper.ScheduleSession(weeks: [3], startSection: 9, endSection: 10, dayOfWeek: EduHelper.DayOfWeek.tuesday, classroom: nil),
            EduHelper.ScheduleSession(weeks: [3], startSection: 9, endSection: 10, dayOfWeek: EduHelper.DayOfWeek.thursday, classroom: nil),
        ]
    ),
    EduHelper.Course(
        courseName: "大学物理B（下）",
        groupName: nil,
        teacher: "张华林讲师",
        sessions: [
            EduHelper.ScheduleSession(weeks: [3], startSection: 5, endSection: 6, dayOfWeek: EduHelper.DayOfWeek.monday, classroom: "金12-106")
        ]
    ),
    EduHelper.Course(
        courseName: "离散结构",
        groupName: nil,
        teacher: "肖红光副教授",
        sessions: [
            EduHelper.ScheduleSession(weeks: [3], startSection: 1, endSection: 2, dayOfWeek: EduHelper.DayOfWeek.wednesday, classroom: "金12-106"),
            EduHelper.ScheduleSession(weeks: [3], startSection: 7, endSection: 8, dayOfWeek: EduHelper.DayOfWeek.friday, classroom: "金13-105"),
        ]
    ),
    EduHelper.Course(
        courseName: "写作与沟通",
        groupName: nil,
        teacher: "陈璐（12）副教授",
        sessions: [
            EduHelper.ScheduleSession(weeks: [3], startSection: 3, endSection: 4, dayOfWeek: EduHelper.DayOfWeek.wednesday, classroom: "金6-304")
        ]
    ),
    EduHelper.Course(
        courseName: "程序设计、算法与数据结构（三）",
        groupName: nil,
        teacher: "陈曦(小)副教授",
        sessions: [
            EduHelper.ScheduleSession(weeks: [3], startSection: 3, endSection: 4, dayOfWeek: EduHelper.DayOfWeek.friday, classroom: "金12-107"),
            EduHelper.ScheduleSession(weeks: [3], startSection: 5, endSection: 6, dayOfWeek: EduHelper.DayOfWeek.wednesday, classroom: "金12-107"),
        ]
    ),
    EduHelper.Course(
        courseName: "操作系统",
        groupName: nil,
        teacher: "胡晋彬副教授",
        sessions: [
            EduHelper.ScheduleSession(weeks: [3], startSection: 1, endSection: 2, dayOfWeek: EduHelper.DayOfWeek.tuesday, classroom: "金12-109")
        ]
    ),
    EduHelper.Course(
        courseName: "马克思主义基本原理",
        groupName: nil,
        teacher: "廖苗副教授",
        sessions: [
            EduHelper.ScheduleSession(weeks: [3], startSection: 5, endSection: 6, dayOfWeek: EduHelper.DayOfWeek.thursday, classroom: "金12-116")
        ]
    ),
    EduHelper.Course(
        courseName: "线性代数",
        groupName: nil,
        teacher: "李铭副教授",
        sessions: [
            EduHelper.ScheduleSession(weeks: [3], startSection: 7, endSection: 8, dayOfWeek: EduHelper.DayOfWeek.thursday, classroom: "金6-107")
        ]
    ),
]

struct WeeklyCoursesEntry: TimelineEntry {
    let date: Date
    let data: CourseScheduleData?

    static func mockEntry(semester: String = "2025-2026-1", semesterStartDate: String = "2025-09-07", date: String = "2025-09-21 17:55") -> WeeklyCoursesEntry {
        let semesterDateFormatter = DateFormatter()
        semesterDateFormatter.dateFormat = "yyyy-MM-dd"
        let semesterStartDate = semesterDateFormatter.date(from: semesterStartDate) ?? .now

        let data = CourseScheduleData(semester: semester, semesterStartDate: semesterStartDate, courses: courses, remarks: [])

        let timeDateFormatter = DateFormatter()
        timeDateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        return WeeklyCoursesEntry(
            date: timeDateFormatter.date(from: date) ?? .now,
            data: data
        )
    }
}
