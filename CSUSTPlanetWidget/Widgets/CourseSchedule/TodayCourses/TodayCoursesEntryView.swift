//
//  TodayCoursesEntryView.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/7/23.
//

import CSUSTKit
import SwiftUI
import WidgetKit

let courses = [
    EduHelper.Course(
        courseName: "软件工程概论", groupName: nil, teacher: "胡立辉高级实验师",
        sessions: [
            EduHelper.ScheduleSession(
                weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13], startSection: 3, endSection: 4,
                dayOfWeek: EduHelper.DayOfWeek.thursday, classroom: Optional("金6-102")
            ),
            EduHelper.ScheduleSession(
                weeks: [1, 3, 5, 7, 9, 11, 13], startSection: 7, endSection: 8,
                dayOfWeek: EduHelper.DayOfWeek.monday, classroom: Optional("金12-205")
            ),
        ]
    ),
    EduHelper.Course(
        courseName: "体育(三)", groupName: Optional("(24计算机跆拳道男11)"), teacher: "余新畅无",
        sessions: [
            EduHelper.ScheduleSession(
                weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], startSection: 3,
                endSection: 4, dayOfWeek: EduHelper.DayOfWeek.monday, classroom: Optional("金西田径场1")
            )
        ]
    ),
    EduHelper.Course(
        courseName: "美术鉴赏(艺术及其他)", groupName: nil, teacher: "赵晖(14)讲师",
        sessions: [
            EduHelper.ScheduleSession(
                weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16], startSection: 9,
                endSection: 10, dayOfWeek: EduHelper.DayOfWeek.wednesday, classroom: Optional("金12-215")
            )
        ]
    ),
    EduHelper.Course(
        courseName: "无人机设计与空天科技导论（自然科学）", groupName: nil, teacher: "张云菲副教授,陈良宇讲师",
        sessions: [
            EduHelper.ScheduleSession(
                weeks: [1, 2, 3, 4, 5, 6, 7, 8], startSection: 9, endSection: 10,
                dayOfWeek: EduHelper.DayOfWeek.tuesday, classroom: nil
            ),
            EduHelper.ScheduleSession(
                weeks: [1, 2, 3, 4, 5, 6, 7, 8], startSection: 9, endSection: 10,
                dayOfWeek: EduHelper.DayOfWeek.thursday, classroom: nil
            ),
        ]
    ),
    EduHelper.Course(
        courseName: "大学物理B（下）", groupName: nil, teacher: "张华林讲师",
        sessions: [
            EduHelper.ScheduleSession(
                weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16], startSection: 5,
                endSection: 6, dayOfWeek: EduHelper.DayOfWeek.monday, classroom: Optional("金12-106")
            )
        ]
    ),
    EduHelper.Course(
        courseName: "离散结构", groupName: nil, teacher: "肖红光副教授",
        sessions: [
            EduHelper.ScheduleSession(
                weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], startSection: 1,
                endSection: 2, dayOfWeek: EduHelper.DayOfWeek.wednesday, classroom: Optional("金12-106")
            ),
            EduHelper.ScheduleSession(
                weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], startSection: 7,
                endSection: 8, dayOfWeek: EduHelper.DayOfWeek.friday, classroom: Optional("金13-105")
            ),
        ]
    ),
    EduHelper.Course(
        courseName: "写作与沟通", groupName: nil, teacher: "陈璐（12）副教授",
        sessions: [
            EduHelper.ScheduleSession(
                weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], startSection: 3, endSection: 4,
                dayOfWeek: EduHelper.DayOfWeek.wednesday, classroom: Optional("金6-304")
            )
        ]
    ),
    EduHelper.Course(
        courseName: "程序设计、算法与数据结构（三）", groupName: nil, teacher: "陈曦(小)副教授",
        sessions: [
            EduHelper.ScheduleSession(
                weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], startSection: 3, endSection: 4,
                dayOfWeek: EduHelper.DayOfWeek.friday, classroom: Optional("金12-107")
            ),
            EduHelper.ScheduleSession(
                weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], startSection: 5, endSection: 6,
                dayOfWeek: EduHelper.DayOfWeek.wednesday, classroom: Optional("金12-107")
            ),
        ]
    ),
    EduHelper.Course(
        courseName: "操作系统", groupName: nil, teacher: "胡晋彬副教授",
        sessions: [
            EduHelper.ScheduleSession(
                weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16], startSection: 1,
                endSection: 2, dayOfWeek: EduHelper.DayOfWeek.tuesday, classroom: Optional("金12-109")
            )
        ]
    ),
    EduHelper.Course(
        courseName: "马克思主义基本原理", groupName: nil, teacher: "廖苗副教授",
        sessions: [
            EduHelper.ScheduleSession(
                weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16], startSection: 5,
                endSection: 6, dayOfWeek: EduHelper.DayOfWeek.thursday, classroom: Optional("金12-116")
            )
        ]
    ),
    EduHelper.Course(
        courseName: "大学物理实验B", groupName: nil, teacher: "蔡爱军讲师",
        sessions: [
            EduHelper.ScheduleSession(
                weeks: [2], startSection: 7, endSection: 8, dayOfWeek: EduHelper.DayOfWeek.wednesday,
                classroom: Optional("金12-500")
            )
        ]
    ),
    EduHelper.Course(
        courseName: "操作系统实验（开源）", groupName: nil, teacher: "胡晋彬副教授",
        sessions: [
            EduHelper.ScheduleSession(
                weeks: [6, 7, 8, 9, 10, 11, 12, 13, 14, 15], startSection: 3, endSection: 4,
                dayOfWeek: EduHelper.DayOfWeek.tuesday, classroom: nil
            ),
            EduHelper.ScheduleSession(
                weeks: [6, 8, 10, 12, 14], startSection: 5, endSection: 6,
                dayOfWeek: EduHelper.DayOfWeek.friday, classroom: nil
            ),
        ]
    ),
    EduHelper.Course(
        courseName: "线性代数", groupName: nil, teacher: "李铭副教授",
        sessions: [
            EduHelper.ScheduleSession(
                weeks: [2, 4, 6, 8, 10, 12, 14], startSection: 1, endSection: 2,
                dayOfWeek: EduHelper.DayOfWeek.monday, classroom: Optional("金6-107")
            ),
            EduHelper.ScheduleSession(
                weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13], startSection: 7, endSection: 8,
                dayOfWeek: EduHelper.DayOfWeek.thursday, classroom: Optional("金6-107")
            ),
        ]
    ),
]

func mockTodayCoursesEntry() -> TodayCoursesEntry {
    let semesterDateFormatter = DateFormatter()
    semesterDateFormatter.dateFormat = "yyyy-MM-dd"

    let data = CourseScheduleData(semester: "2025-2026-1", semesterStartDate: semesterDateFormatter.date(from: "2025-09-07")!, courses: courses)

    let timeDateFormatter = DateFormatter()
    timeDateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

    return TodayCoursesEntry(
        date: timeDateFormatter.date(from: "2025-09-17 04:00")!,
        configuration: TodayCoursesIntent(),
        data: data
    )
}

struct TodayCoursesEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily

    var entry: TodayCoursesProvider.Entry

    var body: some View {
        VStack {
            if let data = entry.data {
                HStack {
                    if widgetFamily != .systemSmall {
                        Text("今日剩余课程")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.primary)
                        Text(data.semester ?? "默认学期")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    Text("周\(CourseScheduleHelper.getDayOfWeek(entry.date).stringValue)")
                        .font(.system(size: 14))
                        .foregroundStyle(.red)

                    Spacer()

                    switch CourseScheduleHelper.getSemesterStatus(semesterStartDate: data.semesterStartDate, date: entry.date) {
                    case .beforeSemester:
                        Text("学期未开始")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    case .afterSemester:
                        Text("学期已结束")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    case .inSemester:
                        if let currentWeek = CourseScheduleHelper.getCurrentWeek(semesterStartDate: data.semesterStartDate, now: entry.date) {
                            Text("第 \(currentWeek) 周")
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                        } else {
                            Text("无法计算当前周")
                                .font(.system(size: 14))
                                .foregroundStyle(.red)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                coursesView(data: data)
            } else {
                Text("请先在App中查询课表")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
        }
        .widgetURL(URL(string: "csustplanet://widgets/courseSchedule"))
    }

    func coursesView(data: CourseScheduleData) -> some View {
        Group {
            switch CourseScheduleHelper.getSemesterStatus(semesterStartDate: data.semesterStartDate, date: entry.date) {
            case .beforeSemester:
                VStack {
                    Text("学期未开始")
                    if let daysUntilStart = CourseScheduleHelper.getDaysUntilSemesterStart(semesterStartDate: data.semesterStartDate, currentDate: entry.date) {
                        Text("还有 \(daysUntilStart) 天开学")
                            .font(.system(size: 12))
                            .foregroundStyle(.primary)
                            .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            case .afterSemester:
                Text("学期已结束")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            case .inSemester:
                let courseColors = ColorHelper.getCourseColors(data.courses)
                let courseDisplayInfos = CourseScheduleHelper.getUnfinishedCourses(semesterStartDate: data.semesterStartDate, now: entry.date, courses: data.courses)
                    .prefix(widgetFamily == .systemLarge ? 5 : 2)

                if courseDisplayInfos.isEmpty {
                    Text("今天已经没有课程啦")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(courseDisplayInfos) { courseDisplayInfo in
                            courseCard(courseDisplayInfo: courseDisplayInfo, courseColors: courseColors)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
        }
    }

    private func courseCard(courseDisplayInfo: CourseDisplayInfo, courseColors: [String: Color]) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(courseDisplayInfo.course.courseName)
                    .font(.system(size: 16, weight: .bold))
                HStack {
                    Text(courseDisplayInfo.session.classroom ?? "无教室")
                        .fixedSize()
                    Text(courseDisplayInfo.course.teacher)
                }
                .font(.system(size: widgetFamily == .systemSmall ? 12 : 14))
                if widgetFamily == .systemSmall {
                    Text("\(CourseScheduleHelper.sectionTimeString[courseDisplayInfo.session.startSection - 1].0) - \(CourseScheduleHelper.sectionTimeString[courseDisplayInfo.session.endSection - 1].1)")
                        .font(.system(size: 12))
                }
            }
            if widgetFamily != .systemSmall {
                Spacer()
                VStack(alignment: .trailing) {
                    Text(CourseScheduleHelper.sectionTimeString[courseDisplayInfo.session.startSection - 1].0)
                        .font(.system(size: 16))
                    Text(CourseScheduleHelper.sectionTimeString[courseDisplayInfo.session.endSection - 1].1)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 50)
        .background((courseColors[courseDisplayInfo.course.courseName] ?? .gray).opacity(0.1))
        .cornerRadius(4)
        .overlay(
            Rectangle()
                .frame(width: 4)
                .foregroundStyle(courseColors[courseDisplayInfo.course.courseName] ?? .gray)
                .cornerRadius(2)
                .padding(.leading, -8),
            alignment: .leading
        )
        .padding(.leading, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview(as: .systemSmall) {
    TodayCoursesWidget()
} timeline: {
    mockTodayCoursesEntry()
}

#Preview(as: .systemMedium) {
    TodayCoursesWidget()
} timeline: {
    mockTodayCoursesEntry()
}

#Preview(as: .systemLarge) {
    TodayCoursesWidget()
} timeline: {
    mockTodayCoursesEntry()
}
