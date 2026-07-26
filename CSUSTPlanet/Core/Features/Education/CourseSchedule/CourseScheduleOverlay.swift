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
                    ForEach(groupCourses(coursesForWeek), id: \.first!.id) { group in
                        let firstCourseInfo = group[0]
                        let startSection = firstCourseInfo.session.startSection
                        let endSection = group.map(\.session.endSection).max()!
                        let courseHeight = calculateHeight(startSection: startSection, endSection: endSection)
                        let xOffset = layoutConfig.horizontalPadding + calculateXOffset(for: firstCourseInfo.session.dayOfWeek, columnWidth: dayColumnWidth)
                        let yOffset = calculateYOffset(startSection: startSection)

                        if group.count > 1 {
                            CourseScheduleConflictCard(courses: group) {
                                presentCourseDetail($0)
                            }
                            .frame(width: dayColumnWidth, height: courseHeight)
                            .offset(x: xOffset, y: yOffset)
                        } else {
                            CourseScheduleCard(course: firstCourseInfo.course, session: firstCourseInfo.session, color: courseColors[firstCourseInfo.course.courseName] ?? .gray) {
                                presentCourseDetail(firstCourseInfo)
                            }
                            .frame(width: dayColumnWidth, height: courseHeight)
                            .offset(x: xOffset, y: yOffset)
                        }
                    }
                }
            }
        }
        .padding(.vertical)
    }

    private func groupCourses(_ courses: [CourseDisplayInfo]) -> [[CourseDisplayInfo]] {
        let sortedCourses = courses.sorted {
            let lhs = $0.session
            let rhs = $1.session

            if lhs.dayOfWeek != rhs.dayOfWeek { return lhs.dayOfWeek.rawValue < rhs.dayOfWeek.rawValue }
            if lhs.startSection != rhs.startSection { return lhs.startSection < rhs.startSection }
            if lhs.endSection != rhs.endSection { return lhs.endSection < rhs.endSection }
            return $0.course.courseName < $1.course.courseName
        }

        return sortedCourses.reduce(into: [[CourseDisplayInfo]]()) { groups, courseInfo in
            if let lastIndex = groups.indices.last {
                let currentGroup = groups[lastIndex]
                let currentEndSection = currentGroup.map(\.session.endSection).max()!

                if currentGroup[0].session.dayOfWeek == courseInfo.session.dayOfWeek,
                    courseInfo.session.startSection <= currentEndSection
                {
                    groups[lastIndex].append(courseInfo)
                    return
                }
            }

            groups.append([courseInfo])
        }
    }

    private func calculateHeight(startSection: Int, endSection: Int) -> CGFloat {
        let sections = CGFloat(endSection - startSection + 1)
        return sections * layoutConfig.sectionHeight + (sections - 1) * layoutConfig.rowSpacing
    }

    private func calculateYOffset(startSection: Int) -> CGFloat {
        let y = CGFloat(startSection - 1)
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
    let sessions = [
        EduHelper.ScheduleSession(weeks: [1], startSection: 1, endSection: 2, dayOfWeek: .monday, classroom: "教室A"),
        EduHelper.ScheduleSession(weeks: [1], startSection: 1, endSection: 4, dayOfWeek: .monday, classroom: "教室B"),
        EduHelper.ScheduleSession(weeks: [1], startSection: 5, endSection: 8, dayOfWeek: .tuesday, classroom: "教室C"),
        EduHelper.ScheduleSession(weeks: [1], startSection: 7, endSection: 9, dayOfWeek: .tuesday, classroom: "教室D"),
        EduHelper.ScheduleSession(weeks: [1], startSection: 9, endSection: 10, dayOfWeek: .tuesday, classroom: "教室E"),
        EduHelper.ScheduleSession(weeks: [1], startSection: 3, endSection: 4, dayOfWeek: .wednesday, classroom: "教室F"),
        EduHelper.ScheduleSession(weeks: [1], startSection: 5, endSection: 6, dayOfWeek: .wednesday, classroom: "教室G"),
    ]

    let courses = sessions.enumerated().map { index, session in
        EduHelper.Course(courseName: "课程\(index + 1)", groupName: nil, teacher: "老师\(index + 1)", sessions: [session])
    }

    let weeklyCourses: [Int: [CourseDisplayInfo]] = [
        1: courses.map { CourseDisplayInfo(course: $0, session: $0.sessions[0]) }
    ]

    let courseColors = ColorUtil.getCourseColors(courses)

    CourseScheduleOverlay(
        targetWeek: 1,
        weeklyCourses: weeklyCourses,
        courseColors: courseColors,
        isCourseDetailInspectorPresented: .constant(false),
        selectedCourseInfo: .constant(nil)
    )
}
