//
//  CourseCardView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/18.
//

import CSUSTKit
import SwiftUI

struct CourseCardView: View {
    @State var isShowingDetail = false

    let course: EduHelper.Course
    let session: EduHelper.ScheduleSession
    let color: Color

    var body: some View {
        VStack(alignment: .leading) {
            Text(course.courseName)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 0)

            Text("@\(session.classroom ?? "待定")")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 0)

            Text(course.teacher)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.white)
                .padding(.horizontal, 0)
        }
        .onTapGesture {
            isShowingDetail = true
        }
        .sheet(isPresented: $isShowingDetail) {
            courseDetailView
        }
        .padding(2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(color)
        .cornerRadius(5)
    }

    struct InfoRow: View {
        let label: String
        let value: String

        var body: some View {
            HStack {
                Text(label)
                Spacer()
                Text(value)
                    .foregroundColor(.secondary)
            }
            .contextMenu {
                Button(action: {
                    UIPasteboard.general.string = value
                }) {
                    Label("复制值", systemImage: "doc.on.doc")
                }
            }
        }
    }

    private var courseDetailView: some View {
        NavigationStack {
            Form {
                Section(header: Text("课程详细")) {
                    InfoRow(label: "课程名称", value: course.courseName)
                    if let groupName = course.groupName {
                        InfoRow(label: "课程分组名称", value: groupName)
                    }
                    InfoRow(label: "授课教师", value: course.teacher)
                }

                Section(header: Text("课程安排")) {
                    InfoRow(label: "课程周次", value: formatWeeks(session.weeks))
                    InfoRow(label: "课程节次", value: "第\(session.startSection)节-第\(session.endSection)节")
                    InfoRow(label: "每周日期", value: "周\(dayOfWeekToString(session.dayOfWeek))")
                    InfoRow(label: "上课教室", value: session.classroom ?? "待定")
                }
            }
            .navigationTitle("课程详情")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        isShowingDetail = false
                    }
                }
            }
        }
    }

    func formatWeeks(_ weeks: [Int]) -> String {
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

    func dayOfWeekToString(_ day: EduHelper.DayOfWeek) -> String {
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
