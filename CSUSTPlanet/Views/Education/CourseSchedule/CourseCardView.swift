//
//  CourseCardView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/18.
//

import SwiftUI

struct CourseCardView: View {
    let course: Course
    let session: ScheduleSession

    private var cardColor: Color {
        let hash = course.courseName.count
        let colorIndex = abs(hash) % 5
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink]
        return colors[colorIndex].opacity(0.8)
    }

    var body: some View {
        VStack {
            Text(course.courseName)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 0)
                .padding(.top, 2)

            Text("@\(session.classroom ?? "待定")")
                .font(.system(size: 13))
                .foregroundColor(.white)
                .padding(.horizontal, 0)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(2)
        .background(cardColor)
        .cornerRadius(5)
    }
}
