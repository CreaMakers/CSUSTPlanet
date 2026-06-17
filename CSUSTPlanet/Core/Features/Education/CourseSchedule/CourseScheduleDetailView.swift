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
    let isShowingToolbar: Bool

    @Environment(\.dismiss) private var dismiss

    private var otherSessions: [EduHelper.ScheduleSession] {
        course.sessions.filter { $0 != session }
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 课程基本信息
                Section {
                    VStack(spacing: 8) {
                        Text(course.courseName)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        HStack(spacing: 12) {
                            if let teacher = course.teacher {
                                Label(teacher, systemImage: "person.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            if let groupName = course.groupName {
                                Text(groupName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.accentColor.opacity(0.12))
                                    .foregroundStyle(.primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // MARK: - 本次安排
                Section("本次安排") {
                    FormRow(label: "课程周次", value: formatWeeks(session.weeks))
                    FormRow(label: "上课时间", value: "\(session.dayOfWeek.chineseLongString) · 第\(session.startSection)-\(session.endSection)节")
                    FormRow(label: "上课教室", value: session.classroom ?? "未安排教室")
                }

                // MARK: - 其他安排
                if !otherSessions.isEmpty {
                    Section("其他安排") {
                        ForEach(otherSessions, id: \.self) { otherSession in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(otherSession.dayOfWeek.chineseLongString)
                                        .fontWeight(.medium)
                                    Text("第\(otherSession.startSection)-\(otherSession.endSection)节")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(otherSession.classroom ?? "未安排教室")
                                        .font(.subheadline)
                                        .foregroundStyle(otherSession.classroom == nil ? .secondary : .primary)
                                }

                                Text(formatWeeks(otherSession.weeks))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("课程详情")
            .inlineToolbarTitle()
            .apply { view in
                if isShowingToolbar {
                    view.toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("关闭") {
                                dismiss()
                            }
                        }
                    }
                } else {
                    view
                }
            }
        }
    }
}

// MARK: - Helpers
extension CourseScheduleDetailView {
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
                    result.append("第\(start)-\(prev)周")
                }
                start = week
                prev = week
            }
        }

        if start == prev {
            result.append("第\(start)周")
        } else {
            result.append("第\(start)-\(prev)周")
        }

        return result.joined(separator: ", ")
    }
}
