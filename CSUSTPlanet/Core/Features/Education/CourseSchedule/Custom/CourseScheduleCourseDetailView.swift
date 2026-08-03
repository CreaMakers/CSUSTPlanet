//
//  CourseScheduleCourseDetailView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/8/2.
//

import CSUSTKit
import Foundation
import GRDB
import SwiftUI

// MARK: - Content

private struct CourseScheduleCourseDetailContent: View {
    let course: CustomCourseGRDB
    let sessions: [CustomSessionGRDB]

    var body: some View {
        Form {
            Section("课程信息") {
                LabeledContent("名称", value: course.courseName)
                if let teacher = course.teacher, !teacher.isEmpty {
                    LabeledContent("教师", value: teacher)
                }
                if let groupName = course.groupName, !groupName.isEmpty {
                    LabeledContent("组名", value: groupName)
                }
            }

            Section("时间安排") {
                if sessions.isEmpty {
                    Text("暂无时间安排")
                        .foregroundStyle(.secondary)
                }
                ForEach(sessions) { session in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(weekdayText(session.dayOfWeek)) · 第 \(session.startSection)-\(session.endSection) 节")
                        Text(sessionSubtitle(session))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(course.courseName)
    }

    // MARK: - Helpers

    private func weekdayText(_ dayOfWeek: Int) -> String {
        guard let day = EduHelper.DayOfWeek(rawValue: dayOfWeek) else {
            return "未知"
        }
        return "周\(day.stringValue)"
    }

    private func sessionSubtitle(_ session: CustomSessionGRDB) -> String {
        let weeks = session.weeks.values.map(String.init).joined(separator: ",")
        var parts: [String] = []
        if let classroom = session.classroom, !classroom.isEmpty {
            parts.append(classroom)
        }
        parts.append("第 \(weeks) 周")
        return parts.joined(separator: " · ")
    }
}

// MARK: - 业务容器

struct CourseScheduleCourseDetailView: View {
    @State var course: CustomCourseGRDB

    @State private var sessions: [CustomSessionGRDB] = []
    @State private var sessionObserver: (any DatabaseCancellable)?
    @State private var isInitial: Bool = true

    var body: some View {
        CourseScheduleCourseDetailContent(
            course: course,
            sessions: sessions
        )
        .task {
            guard isInitial else { return }
            isInitial = false
            observeData()
        }
    }

    // MARK: - 数据观察

    private func observeData() {
        guard let pool = DatabaseManager.shared.pool else { return }

        let observation = ValueObservation.tracking { db -> (CustomCourseGRDB?, [CustomSessionGRDB]) in
            let fetchedCourse = try CustomCourseGRDB.fetchOne(db, key: course.id)
            let sessions =
                try CustomSessionGRDB
                .filter(CustomSessionGRDB.Columns.courseId == course.id)
                .fetchAll(db)
            return (fetchedCourse, sessions)
        }
        .map { result in
            let sortedSessions = result.1.sorted {
                if $0.dayOfWeek != $1.dayOfWeek {
                    return $0.dayOfWeek < $1.dayOfWeek
                }
                return $0.startSection < $1.startSection
            }
            return (result.0, sortedSessions)
        }

        sessionObserver = observation.start(
            in: pool,
            scheduling: .immediate,
            onError: { _ in },
            onChange: { result in
                Task { @MainActor in
                    if let course = result.0 {
                        self.course = course
                    }
                    sessions = result.1
                }
            }
        )
    }
}

#Preview("CourseScheduleCourseDetailContent") {
    NavigationStack {
        CourseScheduleCourseDetailContent(
            course: CustomCourseGRDB(
                id: "preview-course",
                scheduleId: "preview-schedule",
                courseName: "高等数学",
                teacher: "刘文正",
                groupName: "08"
            ),
            sessions: [
                CustomSessionGRDB(
                    id: "1",
                    courseId: "preview-course",
                    dayOfWeek: 1,
                    startSection: 5,
                    endSection: 6,
                    classroom: "金13-106",
                    weeks: JSONIntArray([1, 2, 3, 4, 5, 6, 7, 8])
                ),
                CustomSessionGRDB(
                    id: "2",
                    courseId: "preview-course",
                    dayOfWeek: 3,
                    startSection: 1,
                    endSection: 2,
                    classroom: nil,
                    weeks: JSONIntArray([1, 2, 3, 4, 5, 6, 7, 8])
                ),
            ]
        )
    }
}
