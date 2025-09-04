//
//  HomeUrgentCoursesView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import SwiftUI

struct HomeUrgentCoursesView: View {
    let urgentCourseData: UrgentCourseData?

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            NavigationLink(destination: UrgentCoursesView()) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.red)

                        Text("待提交作业")
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
            if let urgentData = urgentCourseData {
                if !urgentData.courses.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(urgentData.courses.prefix(2).enumerated()), id: \.offset) { index, course in
                            courseCard(course: course)

                            if index < min(urgentData.courses.count, 2) - 1 {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }

                        if urgentData.courses.count > 2 {
                            HStack {
                                Text("...")
                                    .font(.headline)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text("还有 \(urgentData.courses.count - 2) 门课程")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                        }
                    }
                } else {
                    emptyStateView(
                        icon: "doc.text",
                        title: "暂无待提交作业",
                        description: "当前没有待提交作业"
                    )
                    .padding(.vertical, 20)
                }
            } else {
                emptyStateView(
                    icon: "doc.text",
                    title: "暂无作业数据",
                    description: "请前往待提交作业页面加载数据"
                )
                .padding(.vertical, 20)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func courseCard(course: UrgentCourseData.Course) -> some View {
        HStack {
            Circle()
                .fill(.orange.opacity(0.2))
                .frame(width: 8, height: 8)

            Text(course.name)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()
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
    HomeUrgentCoursesView(urgentCourseData: nil)
}
