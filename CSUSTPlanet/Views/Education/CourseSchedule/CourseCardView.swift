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

    let course: Course
    let session: ScheduleSession

    private var cardColor: Color {
        let hash = course.courseName.count
        let colorIndex = abs(hash) % 13
        let colors: [Color] = [
            .blue, .green, .orange, .purple, .pink,
            .red, .yellow, .cyan, .mint, .indigo,
            .teal, .brown, .gray,
        ]
        return colors[colorIndex].opacity(0.8)
    }

    var body: some View {
        VStack {
            Text(course.courseName)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 0)

            Text("@\(session.classroom ?? "待定")")
                .font(.system(size: 13))
                .foregroundColor(.white)
                .padding(.horizontal, 0)

            Text(course.teacher)
                .font(.system(size: 10))
                .foregroundColor(.white)
                .padding(.horizontal, 0)

            Spacer()
        }
        .onTapGesture {
            isShowingDetail = true
        }
        .sheet(isPresented: $isShowingDetail) {
            courseDetailView
        }
        .padding(2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(cardColor)
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
                    InfoRow(label: "课程周次", value: session.weeks.map { "\($0)" }.joined(separator: ", "))
                    InfoRow(label: "课程节次", value: "\(session.startSection) - \(session.endSection)")
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

    func dayOfWeekToString(_ day: DayOfWeek) -> String {
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
