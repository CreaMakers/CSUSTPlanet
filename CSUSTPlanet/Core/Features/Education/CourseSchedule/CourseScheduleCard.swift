//
//  CourseScheduleCard.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/6/18.
//

import CSUSTKit
import SwiftUI

struct CourseScheduleCard: View {
    let course: EduHelper.Course
    let session: EduHelper.ScheduleSession
    let color: Color

    let onTap: () -> Void

    @Environment(\.courseScheduleLayoutConfig) private var layoutConfig

    var body: some View {
        VStack(alignment: .leading, spacing: layoutConfig.isWideSize ? 6 : 2) {
            Text(course.courseName)
                .font(.system(size: layoutConfig.isWideSize ? 16 : 12, weight: .bold))
                .foregroundColor(.white)
                // .lineLimit(3)
                // .minimumScaleFactor(0.8)
                // .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(0)

            // Spacer()

            VStack(alignment: .leading, spacing: layoutConfig.isWideSize ? 4 : 1) {
                // 教室
                if let classroom = session.classroom, !classroom.isEmpty {
                    Text("@" + classroom)
                        .font(.system(size: layoutConfig.isWideSize ? 14 : 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.95))
                        .lineLimit(nil)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                }

                // 老师
                if let teacher = course.teacher, !teacher.isEmpty {
                    Text(teacher)
                        .font(.system(size: layoutConfig.isWideSize ? 14 : 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(nil)
                        .minimumScaleFactor(0.85)
                    // .fixedSize(horizontal: false, vertical: true)
                }
            }
            .layoutPriority(1)
        }
        .padding(.horizontal, layoutConfig.isWideSize ? 6 : 2)
        .padding(.vertical, layoutConfig.isWideSize ? 8 : 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            color
                .cornerRadius(layoutConfig.isWideSize ? 10 : 6)
                .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
        )
        .onTapGesture(perform: onTap)
    }
}

#Preview("CourseScheduleCard") {
    let sessionB = EduHelper.ScheduleSession(weeks: [1], startSection: 5, endSection: 6, dayOfWeek: .wednesday, classroom: "教室B")
    let courseB = EduHelper.Course(courseName: "课程B", groupName: nil, teacher: "老师B", sessions: [sessionB])

    CourseScheduleCard(course: courseB, session: sessionB, color: .yellow, onTap: {})
}
