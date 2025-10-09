//
//  HomeTodayCoursesView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import SwiftUI

struct HomeTodayCoursesView: View {
    let courseScheduleData: CourseScheduleData?
    let todayCourses: [CourseDisplayInfo]

    func formatCourseTime(_ startSection: Int, _ endSection: Int) -> String {
        let sectionTimes: [(String, String)] = [
            ("08:00", "08:45"),
            ("08:55", "09:40"),
            ("10:10", "10:55"),
            ("11:05", "11:50"),
            ("14:00", "14:45"),
            ("14:55", "15:40"),
            ("16:10", "16:55"),
            ("17:05", "17:50"),
            ("19:30", "20:15"),
            ("20:25", "21:10"),
        ]

        let startIndex = startSection - 1
        let endIndex = endSection - 1

        guard startIndex >= 0 && startIndex < sectionTimes.count,
            endIndex >= 0 && endIndex < sectionTimes.count
        else {
            return "时间未知"
        }

        return "\(sectionTimes[startIndex].0) - \(sectionTimes[endIndex].1)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            NavigationLink(destination: CourseScheduleView()) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.purple)

                        Text("今日课程")
                            .foregroundColor(.primary)
                    }
                    .font(.headline)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            Divider()

            // 内容
            if courseScheduleData != nil {
                if !todayCourses.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(todayCourses.enumerated()), id: \.offset) { index, course in
                            courseCard(course: course)

                            if index < todayCourses.count - 1 {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                } else {
                    emptyStateView(
                        icon: "calendar",
                        title: "今天没有课程",
                        description: "好好享受空闲时光吧"
                    )
                    .padding(.vertical, 20)
                }
            } else {
                emptyStateView(
                    icon: "calendar",
                    title: "暂无课程数据",
                    description: "请前往我的课表页面加载数据"
                )
                .padding(.vertical, 20)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func courseCard(course: CourseDisplayInfo) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(course.course.courseName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    if let classroom = course.session.classroom {
                        Text(classroom)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(course.course.teacher)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCourseTime(course.session.startSection, course.session.endSection))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)

                Text("第\(course.session.startSection)-\(course.session.endSection)节")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func emptyStateView(icon: String, title: String, description: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.secondary)

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeTodayCoursesView(
        courseScheduleData: nil,
        todayCourses: []
    )
}
