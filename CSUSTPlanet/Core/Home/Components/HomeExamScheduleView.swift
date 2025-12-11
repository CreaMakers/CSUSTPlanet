//
//  HomeExamScheduleView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import SwiftUI

struct HomeExamScheduleView: View {
    let examScheduleData: Cached<[EduHelper.Exam]>?

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            NavigationLink(destination: ExamScheduleView()) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.orange)

                        Text("考试安排")
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
            if let examData = examScheduleData {
                if !examData.value.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(Array(examData.value.enumerated()), id: \.offset) { index, exam in
                            examCard(exam: exam)

                            if index < examData.value.count - 1 {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                } else {
                    emptyStateView(
                        icon: "calendar.badge.clock",
                        title: "暂无考试安排",
                        description: "当前没有考试安排"
                    )
                    .padding(.vertical, 20)
                }
            } else {
                emptyStateView(
                    icon: "calendar.badge.clock",
                    title: "暂无考试数据",
                    description: "请前往考试安排页面加载数据"
                )
                .padding(.vertical, 20)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func examCard(exam: EduHelper.Exam) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exam.courseName)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)

            HStack(spacing: 12) {
                Label(exam.examTime, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !exam.examRoom.isEmpty {
                    Label(exam.examRoom, systemImage: "building.columns")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
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
    HomeExamScheduleView(examScheduleData: nil)
}
