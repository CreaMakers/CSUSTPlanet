//
//  CourseScheduleOverlay.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/6/18.
//

import CSUSTKit
import SwiftUI

struct CourseScheduleOverlay: View {
    @Environment(\.courseScheduleLayoutConfig) private var layoutConfig

    let targetWeek: Int
    let weeklyCourses: [Int: [CourseDisplayInfo]]
    let courseColors: [String: Color]

    @Binding var isCourseDetailInspectorPresented: Bool
    @Binding var selectedCourseInfo: CourseDisplayInfo?

    var body: some View {
        GeometryReader { geometry in
            let contentWidth = geometry.size.width - (layoutConfig.horizontalPadding * 2)
            let totalSpacingWidth = layoutConfig.colSpacing * 7
            let dayColumnWidth = (contentWidth - layoutConfig.timeColWidth - totalSpacingWidth) / 7

            ZStack(alignment: .topLeading) {
                if let coursesForWeek = weeklyCourses[targetWeek] {
                    let groupedCourses = Dictionary(grouping: coursesForWeek) { info in
                        "\(info.session.dayOfWeek.rawValue)-\(info.session.startSection)"
                    }

                    ForEach(Array(groupedCourses.values), id: \.first!.id) { group in
                        if let firstCourseInfo = group.first {
                            let courseHeight = calculateHeight(for: firstCourseInfo.session)
                            let xOffset = layoutConfig.horizontalPadding + calculateXOffset(for: firstCourseInfo.session.dayOfWeek, columnWidth: dayColumnWidth)
                            let yOffset = calculateYOffset(for: firstCourseInfo.session)

                            if group.count == 1 {
                                // 正常课程
                                CourseScheduleCard(course: firstCourseInfo.course, session: firstCourseInfo.session, color: courseColors[firstCourseInfo.course.courseName] ?? .gray) {
                                    presentCourseDetail(firstCourseInfo)
                                }
                                .frame(width: dayColumnWidth, height: courseHeight)
                                .offset(x: xOffset, y: yOffset)
                            } else {
                                // 冲突课程
                                CourseScheduleConflictCard(courses: group) {
                                    presentCourseDetail($0)
                                }
                                .frame(width: dayColumnWidth, height: courseHeight)
                                .offset(x: xOffset, y: yOffset)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical)
    }

    private func calculateHeight(for session: EduHelper.ScheduleSession) -> CGFloat {
        let sections = CGFloat(session.endSection - session.startSection + 1)
        return sections * layoutConfig.sectionHeight + (sections - 1) * layoutConfig.rowSpacing
    }

    private func calculateYOffset(for session: EduHelper.ScheduleSession) -> CGFloat {
        let y = CGFloat(session.startSection - 1)
        return y * layoutConfig.sectionHeight + y * layoutConfig.rowSpacing
    }

    private func calculateXOffset(for day: EduHelper.DayOfWeek, columnWidth: CGFloat) -> CGFloat {
        let x = CGFloat(day.rawValue)
        return layoutConfig.timeColWidth + layoutConfig.colSpacing + (x * columnWidth) + (x * layoutConfig.colSpacing)
    }

    private func presentCourseDetail(_ courseInfo: CourseDisplayInfo) {
        selectedCourseInfo = courseInfo
        isCourseDetailInspectorPresented = true
    }
}

#Preview("CourseScheduleOverlay") {
    let sessionA1 = EduHelper.ScheduleSession(weeks: [1], startSection: 1, endSection: 2, dayOfWeek: .monday, classroom: "教室A1")
    let sessionA2 = EduHelper.ScheduleSession(weeks: [1], startSection: 5, endSection: 8, dayOfWeek: .tuesday, classroom: "教室A2")
    let sessionA3 = EduHelper.ScheduleSession(weeks: [1], startSection: 3, endSection: 4, dayOfWeek: .wednesday, classroom: "教室A3")
    let courseA = EduHelper.Course(courseName: "课程A", groupName: nil, teacher: "老师A", sessions: [sessionA1, sessionA2, sessionA3])

    let sessionB = EduHelper.ScheduleSession(weeks: [1], startSection: 5, endSection: 6, dayOfWeek: .wednesday, classroom: "教室B")
    let courseB = EduHelper.Course(courseName: "课程B", groupName: nil, teacher: "老师B", sessions: [sessionB])

    let courseC = EduHelper.Course(courseName: "课程C", groupName: nil, teacher: "老师C", sessions: [sessionA3])

    let weeklyCourses: [Int: [CourseDisplayInfo]] = [
        1: [
            CourseDisplayInfo(course: courseA, session: courseA.sessions[0]),
            CourseDisplayInfo(course: courseA, session: courseA.sessions[1]),
            CourseDisplayInfo(course: courseA, session: courseA.sessions[2]),
            CourseDisplayInfo(course: courseB, session: courseB.sessions[0]),
            CourseDisplayInfo(course: courseC, session: courseC.sessions[0]),  // 冲突
        ]
    ]

    let courseColors: [String: Color] = [
        "课程A": .blue,
        "课程B": .green,
        "课程C": .yellow,
    ]

    CourseScheduleOverlay(
        targetWeek: 1,
        weeklyCourses: weeklyCourses,
        courseColors: courseColors,
        isCourseDetailInspectorPresented: .constant(false),
        selectedCourseInfo: .constant(nil)
    )
}
