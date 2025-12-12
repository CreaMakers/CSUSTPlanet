//
//  CourseScheduleDetailView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import SwiftUI

struct CourseScheduleDetailView: View {
    let course: EduHelper.Course
    let session: EduHelper.ScheduleSession
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("课程详细")) {
                    InfoRow(label: "课程名称", value: course.courseName)
                    if let groupName = course.groupName {
                        InfoRow(label: "课程分组名称", value: groupName)
                    }
                    if let teacher = course.teacher {
                        InfoRow(label: "授课教师", value: teacher)
                    }
                }

                Section(header: Text("课程安排")) {
                    InfoRow(label: "课程周次", value: formatWeeks(session.weeks))
                    InfoRow(label: "课程节次", value: "第\(session.startSection)节-第\(session.endSection)节")
                    InfoRow(label: "每周日期", value: "周\(dayOfWeekToString(session.dayOfWeek))")
                    InfoRow(label: "上课教室", value: session.classroom ?? "无教室")
                }
            }
            .navigationTitle("课程详情")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func formatWeeks(_ weeks: [Int]) -> String {
        guard !weeks.isEmpty else { return "" }

        var result = [String]()
        var start = weeks[0]
        var prev = weeks[0]

        for week in weeks.dropFirst() {
            if week == prev + 1 {
                prev = week
            } else {
                if start == prev {
                    result.append("第\(start)周")
                } else {
                    result.append("第\(start)周-第\(prev)周")
                }
                start = week
                prev = week
            }
        }

        if start == prev {
            result.append("第\(start)周")
        } else {
            result.append("第\(start)周-第\(prev)周")
        }

        return result.joined(separator: ", ")
    }

    private func dayOfWeekToString(_ day: EduHelper.DayOfWeek) -> String {
        switch day {
        case .monday: return "一"
        case .tuesday: return "二"
        case .wednesday: return "三"
        case .thursday: return "四"
        case .friday: return "五"
        case .saturday: return "六"
        case .sunday: return "日"
        }
    }
}
