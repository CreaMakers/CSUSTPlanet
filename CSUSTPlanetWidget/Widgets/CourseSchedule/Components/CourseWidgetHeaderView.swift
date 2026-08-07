//
//  CourseWidgetHeaderView.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zachary Liu on 2026/2/25.
//

import SwiftUI
import WidgetKit

struct CourseWidgetHeaderView: View {
    let family: WidgetFamily
    let title: String
    let date: Date
    let data: CourseScheduleData
    let scheduleName: String?

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            if family != .systemSmall {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
                Text(scheduleName ?? data.semester ?? "默认学期")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            Text("周\(CourseScheduleUtil.getDayOfWeek(date).stringValue)")
                .font(.system(size: 14))
                .foregroundStyle(.red)

            Spacer()

            switch CourseScheduleUtil.getSemesterStatus(semesterStartDate: data.semesterStartDate, date: date, weekCount: data.weekCount) {
            case .beforeSemester:
                Text(CourseScheduleUtil.semesterNotStartedText)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            case .afterSemester:
                Text(CourseScheduleUtil.semesterEndedText)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            case .inSemester:
                if let currentWeek = CourseScheduleUtil.getCurrentWeek(semesterStartDate: data.semesterStartDate, now: date, weekCount: data.weekCount) {
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
    }
}
