//
//  CourseCardView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/18.
//

import CSUSTKit
import Inject
import SwiftUI

struct CourseCardView: View {
    @ObserveInjection var inject
    @State var isShowingDetail = false

    let course: EduHelper.Course
    let session: EduHelper.ScheduleSession
    let color: Color

    var body: some View {
        VStack(alignment: .leading) {
            Text(course.courseName)
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(.white)
                .padding(.horizontal, 0)

            Text("@\(session.classroom ?? "无教室")")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 0)

            Text(course.teacher ?? "无教师")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 0)
        }
        .onTapGesture {
            isShowingDetail = true
        }
        .sheet(isPresented: $isShowingDetail) {
            CourseScheduleDetailView(course: course, session: session, isPresented: $isShowingDetail)
        }
        .padding(4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(color)
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(.white.opacity(0.6), lineWidth: 3)
        )
        .enableInjection()
    }

}
