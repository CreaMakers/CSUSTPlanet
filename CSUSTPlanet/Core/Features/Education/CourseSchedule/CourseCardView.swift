//
//  CourseCardView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/18.
//

import CSUSTKit
import SwiftUI

struct CourseCardView: View {
    let course: EduHelper.Course
    let session: EduHelper.ScheduleSession
    let color: Color

    let onTap: () -> Void

    @Environment(\.horizontalSizeClass) var sizeClass

    private var isPad: Bool {
        sizeClass == .regular
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isPad ? 6 : 2) {
            Text(course.courseName)
                .font(.system(size: isPad ? 16 : 12, weight: .bold))
                .foregroundColor(.white)
                // .lineLimit(3)
                // .minimumScaleFactor(0.8)
                // .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(0)

            // Spacer()

            VStack(alignment: .leading, spacing: isPad ? 4 : 1) {
                // 教室
                if let classroom = session.classroom, !classroom.isEmpty {
                    Text("@" + classroom)
                        .font(.system(size: isPad ? 14 : 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.95))
                        .lineLimit(nil)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                }

                // 老师
                if let teacher = course.teacher, !teacher.isEmpty {
                    Text(teacher)
                        .font(.system(size: isPad ? 14 : 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(nil)
                        .minimumScaleFactor(0.85)
                    // .fixedSize(horizontal: false, vertical: true)
                }
            }
            .layoutPriority(1)
        }
        .padding(.horizontal, isPad ? 6 : 2)
        .padding(.vertical, isPad ? 8 : 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            color
                .cornerRadius(isPad ? 10 : 6)
                .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
        )
        .onTapGesture {
            onTap()
        }
    }
}
