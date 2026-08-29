//
//  CourseScheduleScrollTable.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/6/18.
//

import SwiftUI

struct CourseScheduleScrollTable: View {
    let semesterStartDate: Date
    let weeklyCourses: [Int: [CourseDisplayInfo]]
    let courseColors: [String: Color]

    @Binding var currentWeek: Int
    let weekCount: Int
    @Binding var isCourseDetailInspectorPresented: Bool
    @Binding var selectedCourseInfo: CourseDisplayInfo?

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(1...weekCount, id: \.self) { week in
                        CourseScheduleTable(
                            semesterStartDate: semesterStartDate,
                            targetWeek: week,
                            weeklyCourses: weeklyCourses,
                            courseColors: courseColors,
                            isCourseDetailInspectorPresented: $isCourseDetailInspectorPresented,
                            selectedCourseInfo: $selectedCourseInfo
                        )
                        .padding(.leading, geometry.safeAreaInsets.leading)
                        .padding(.trailing, geometry.safeAreaInsets.trailing)
                        .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            #if os(iOS)
            .ignoresSafeArea(.container, edges: .horizontal)
            #endif
            .scrollPosition(
                id: Binding<Int?>(
                    get: { currentWeek },
                    set: { if let newWeek = $0 { currentWeek = newWeek } }
                )
            )
        }
    }
}

#Preview("CourseScheduleScrollTable") {
    CourseScheduleScrollTable(
        semesterStartDate: .init(timeIntervalSince1970: 1_781_366_400),
        weeklyCourses: [:],
        courseColors: [:],
        currentWeek: .constant(1),
        weekCount: 20,
        isCourseDetailInspectorPresented: .constant(false),
        selectedCourseInfo: .constant(nil)
    )
}
