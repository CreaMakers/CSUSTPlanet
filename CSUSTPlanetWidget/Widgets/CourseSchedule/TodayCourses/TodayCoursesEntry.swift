//
//  TodayCoursesEntry.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/24.
//

import CSUSTKit
import WidgetKit

private let defaultPreviewCourses = [
    EduHelper.Course(
        courseName: "美术鉴赏(艺术及其他)",
        groupName: nil,
        teacher: "赵晖(14)讲师",
        sessions: [EduHelper.ScheduleSession(weeks: [2], startSection: 9, endSection: 10, dayOfWeek: EduHelper.DayOfWeek.wednesday, classroom: "金12-215")]
    ),
    EduHelper.Course(
        courseName: "离散结构",
        groupName: nil,
        teacher: "肖红光副教授",
        sessions: [EduHelper.ScheduleSession(weeks: [2], startSection: 1, endSection: 2, dayOfWeek: EduHelper.DayOfWeek.wednesday, classroom: "金12-106")]
    ),
    EduHelper.Course(
        courseName: "写作与沟通",
        groupName: nil,
        teacher: "陈璐（12）副教授",
        sessions: [EduHelper.ScheduleSession(weeks: [2], startSection: 3, endSection: 4, dayOfWeek: EduHelper.DayOfWeek.wednesday, classroom: "金6-304")]
    ),
    EduHelper.Course(
        courseName: "程序设计、算法与数据结构（三）",
        groupName: nil,
        teacher: "陈曦(小)副教授",
        sessions: [EduHelper.ScheduleSession(weeks: [2], startSection: 5, endSection: 6, dayOfWeek: EduHelper.DayOfWeek.wednesday, classroom: "金12-107")]
    ),
    EduHelper.Course(
        courseName: "大学物理实验B",
        groupName: nil,
        teacher: "蔡爱军讲师",
        sessions: [EduHelper.ScheduleSession(weeks: [2], startSection: 7, endSection: 8, dayOfWeek: EduHelper.DayOfWeek.wednesday, classroom: "金12-500")]
    ),
]

private let tomorrowPreviewCourses =
    defaultPreviewCourses + [
        EduHelper.Course(
            courseName: "线性代数",
            groupName: nil,
            teacher: "张文副教授",
            sessions: [EduHelper.ScheduleSession(weeks: [2], startSection: 1, endSection: 2, dayOfWeek: EduHelper.DayOfWeek.thursday, classroom: "理科楼101")]
        ),
        EduHelper.Course(
            courseName: "数据结构实验",
            groupName: nil,
            teacher: "周峰副教授",
            sessions: [EduHelper.ScheduleSession(weeks: [2], startSection: 3, endSection: 4, dayOfWeek: EduHelper.DayOfWeek.thursday, classroom: "计科楼305")]
        ),
        EduHelper.Course(
            courseName: "概率论",
            groupName: nil,
            teacher: "何敏教授",
            sessions: [EduHelper.ScheduleSession(weeks: [2], startSection: 5, endSection: 6, dayOfWeek: EduHelper.DayOfWeek.thursday, classroom: "金12-401")]
        ),
        EduHelper.Course(
            courseName: "体育(羽毛球)",
            groupName: nil,
            teacher: "陈亮老师",
            sessions: [EduHelper.ScheduleSession(weeks: [2], startSection: 7, endSection: 8, dayOfWeek: EduHelper.DayOfWeek.thursday, classroom: "体育馆B")]
        ),
        EduHelper.Course(
            courseName: "形势与政策",
            groupName: nil,
            teacher: "刘洋讲师",
            sessions: [EduHelper.ScheduleSession(weeks: [2], startSection: 9, endSection: 10, dayOfWeek: EduHelper.DayOfWeek.thursday, classroom: "文科楼118")]
        ),
    ]

struct TodayCoursesEntry: TimelineEntry {
    let date: Date
    let data: CourseScheduleData?

    static func mockEntry(
        semester: String = "2025-2026-1",
        semesterStartDate: String = "2025-09-07",
        date: String = "2025-09-17 04:00",
        previewCourses: [EduHelper.Course] = defaultPreviewCourses
    ) -> TodayCoursesEntry {
        let semesterDateFormatter = DateFormatter()
        semesterDateFormatter.dateFormat = "yyyy-MM-dd"
        let semesterStartDate = semesterDateFormatter.date(from: semesterStartDate) ?? .now

        let data = CourseScheduleData(semester: semester, semesterStartDate: semesterStartDate, courses: previewCourses, remarks: [])

        let timeDateFormatter = DateFormatter()
        timeDateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        return TodayCoursesEntry(
            date: timeDateFormatter.date(from: date) ?? .now,
            data: data
        )
    }

    static func mockTomorrowPreviewEntry(
        semester: String = "2025-2026-1",
        semesterStartDate: String = "2025-09-07",
        date: String = "2025-09-17 22:00"
    ) -> TodayCoursesEntry {
        mockEntry(
            semester: semester,
            semesterStartDate: semesterStartDate,
            date: date,
            previewCourses: tomorrowPreviewCourses
        )
    }
}
