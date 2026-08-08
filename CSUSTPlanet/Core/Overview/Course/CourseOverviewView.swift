//
//  CourseOverviewView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import Foundation
import SwiftUI

struct CourseOverviewView: View {
    @State private var viewModel = CourseOverviewViewModel()
    @Environment(Router.self) private var router
    @State private var selectedCourse: CourseDisplayInfo?

    var body: some View {
        Button(action: { router.deepLinkTo(feature: .courseSchedule) }) {
            CustomGroupBox {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    cardContent(now: context.date)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .sheet(item: $selectedCourse) { courseInfo in
            NavigationStack {
                CourseScheduleDetailView(
                    course: courseInfo.course,
                    session: courseInfo.session,
                    isToolbarPresented: true,
                )
            }
        }
    }

    private var courseDetailBinding: Binding<Bool> {
        Binding(
            get: { selectedCourse != nil },
            set: { isPresented in
                if !isPresented {
                    selectedCourse = nil
                }
            }
        )
    }

    @ViewBuilder
    private func cardContent(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(CourseScheduleUtil.courseScheduleTitle)
                    .font(.title3)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)

                Text(viewModel.semesterInfoText)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
            }

            contentView(now: now)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func contentView(now: Date) -> some View {
        switch viewModel.courseDisplayState(at: now) {
        case .loading:
            EmptyCourseContentView(text: CourseScheduleUtil.emptyCourseScheduleText)

        case .beforeSemester(let days):
            if let days {
                if days > CourseScheduleUtil.semesterStartThreshold {
                    EmptyCourseContentView(
                        text: CourseScheduleUtil.getHolidayMessage(for: now),
                        subtitle: CourseScheduleUtil.semesterNotStartedText
                    )
                } else {
                    EmptyCourseContentView(
                        text: CourseScheduleUtil.semesterNotStartedText,
                        subtitle: CourseScheduleUtil.getSemesterCountdownText(days: days)
                    )
                }
            } else {
                EmptyCourseContentView(text: CourseScheduleUtil.semesterNotStartedText)
            }

        case .afterSemester:
            EmptyCourseContentView(text: CourseScheduleUtil.semesterEndedText)

        case .inSemester(let dailyCourseState):
            switch dailyCourseState {
            case .today(let courses):
                CourseListView(
                    courses: courseItems(from: courses),
                    onSelect: { selectedCourse = $0 }
                )
            case .tomorrowPreview(let reason, let preview):
                if let preview {
                    VStack(alignment: .leading, spacing: 8) {
                        TomorrowPreviewStatusView(
                            text: reason.message,
                            courseCount: preview.courses.count
                        )

                        TomorrowCourseSectionView(
                            preview: preview,
                            onSelect: { selectedCourse = $0 }
                        )
                    }
                } else {
                    EmptyCourseContentView(
                        text: reason.message,
                        subtitle: CourseScheduleUtil.noScheduledCoursesTomorrowText
                    )
                }
            }
        }
    }

    private func courseItems(from courses: [(course: CourseDisplayInfo, isCurrent: Bool)]) -> [CourseRowItem] {
        courses.map { course in
            CourseRowItem(courseInfo: course.course, isCurrent: course.isCurrent)
        }
    }
}

private struct CourseRowItem: Identifiable {
    let courseInfo: CourseDisplayInfo
    let isCurrent: Bool

    var id: UUID { courseInfo.id }
}

private struct CourseListView: View {
    let courses: [CourseRowItem]
    let onSelect: (CourseDisplayInfo) -> Void

    private var courseColors: [String: Color] {
        ColorUtil.getCourseColors(courses.map { $0.courseInfo.course })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(courses) { item in
                CourseRowView(
                    courseInfo: item.courseInfo,
                    isCurrent: item.isCurrent,
                    accentColor: courseColors[item.courseInfo.course.courseName] ?? .blue,
                    onTap: { onSelect(item.courseInfo) }
                )
            }
        }
    }
}

private struct TomorrowCourseSectionView: View {
    let preview: TomorrowCoursePreview
    let onSelect: (CourseDisplayInfo) -> Void

    var body: some View {
        CourseListView(
            courses: preview.courses.map { CourseRowItem(courseInfo: $0, isCurrent: false) },
            onSelect: onSelect
        )
    }
}

private struct TomorrowPreviewStatusView: View {
    let text: String
    let courseCount: Int

    var body: some View {
        HStack(spacing: 0) {
            Text(text)
                .padding(.trailing, 8)
            Text(CourseScheduleUtil.tomorrowCoursesTitleText)
                .foregroundStyle(.red)
                .padding(.trailing, 8)
            Text("共")
            Text("\(courseCount)")
                .foregroundStyle(.blue)
            Text("节课程")
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .font(.system(size: 13, weight: .bold))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CourseRowView: View {
    let courseInfo: CourseDisplayInfo
    let isCurrent: Bool
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        let course = courseInfo.course
        let session = courseInfo.session
        let startSection = courseInfo.session.startSection
        let endSection = courseInfo.session.endSection

        Button(action: onTap) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor)
                    .frame(width: 4)

                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Text(course.courseName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            if isCurrent {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 8, height: 8)
                            }
                        }

                        HStack(spacing: 6) {
                            Text(session.classroom ?? "未安排教室")
                                .lineLimit(1)

                            if let teacher = course.teacher, !teacher.isEmpty {
                                Text(teacher)
                                    .lineLimit(1)
                            }
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)

                    VStack(alignment: .trailing, spacing: 6) {
                        Text(CourseScheduleUtil.sectionTimeString[startSection - 1].0)
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(CourseScheduleUtil.sectionTimeString[endSection - 1].1)
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    .padding(.trailing, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyCourseContentView: View {
    var text: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
