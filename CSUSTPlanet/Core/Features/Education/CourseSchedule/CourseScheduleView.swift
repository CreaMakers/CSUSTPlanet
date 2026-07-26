//
//  CourseScheduleView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import AlertToast
import CSUSTKit
import Foundation
import SwiftUI

struct CourseScheduleView: View {
    @State private var courses: [EduHelper.Course]? = nil
    @State private var weeklyCourses: [Int: [CourseDisplayInfo]]? = nil
    @State private var courseColors: [String: Color] = [:]
    @State private var semesterStartDate: Date? = nil
    @State private var remarks: [String] = []

    @State private var selectedSemester: String? = nil

    @State private var isCourseScheduleLoading: Bool = false
    @State private var isCalendarExporting: Bool = false

    @State private var currentWeek: Int = 1
    @State private var realCurrentWeek: Int? = nil

    @State private var errorToast: ToastState = .errorTitle
    @State private var loadingToast: ToastState = .loadingTitle
    @State private var successToast: ToastState = .successTitle

    @State private var isInitial: Bool = true

    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        CourseScheduleContent(
            weeklyCourses: weeklyCourses,
            courseColors: courseColors,
            semesterStartDate: semesterStartDate,
            remarks: remarks,
            selectedSemester: selectedSemester,
            isCourseScheduleLoading: isCourseScheduleLoading,
            isCalendarExporting: isCalendarExporting,
            currentWeek: $currentWeek,
            realCurrentWeek: realCurrentWeek,
            errorToast: $errorToast,
            loadingToast: $loadingToast,
            successToast: $successToast,
            onRefreshCourses: {
                await loadCourses(selectedSemester: selectedSemester)
            },
            onSelectSemester: { selectedSemester in
                await loadCourses(selectedSemester: selectedSemester)
            },
            onAddCalendar: addToCalendar
        )
        .onReceive(MMKVHelper.CourseSchedule.$cache.dropFirst().receive(on: RunLoop.main)) { data in
            applyData(data)
        }
        .task {
            guard isInitial else {
                return
            }
            isInitial = false
            applyData(MMKVHelper.CourseSchedule.cache)
            await loadCourses(selectedSemester: selectedSemester)
        }
    }

    // MARK: - Methods

    private func loadCourses(selectedSemester: String?) async {
        guard !isCourseScheduleLoading else { return }
        isCourseScheduleLoading = true
        defer { isCourseScheduleLoading = false }

        do {
            let (courses, remarks) = try await AuthManager.shared.withAuthRetry(system: .edu) {
                try await AuthManager.shared.eduHelper.courseService.getCourseSchedule(academicYearSemester: selectedSemester)
            }
            let rawSemesterStartDate = try await AuthManager.shared.withAuthRetry(system: .edu) {
                try await AuthManager.shared.eduHelper.semesterService.getSemesterStartDate(academicYearSemester: selectedSemester)
            }
            let semesterStartDate = CourseScheduleUtil.normalizeSemesterStartDate(rawSemesterStartDate)

            let data = Cached<CourseScheduleData>(
                cachedAt: .now,
                value: CourseScheduleData(
                    semester: selectedSemester,
                    semesterStartDate: semesterStartDate,
                    courses: courses,
                    remarks: remarks
                )
            )
            MMKVHelper.CourseSchedule.cache = data
            WidgetTimelineRefreshHelper.reloadCourseScheduleWidgets()

            self.selectedSemester = selectedSemester
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func applyData(_ data: Cached<CourseScheduleData>?) {
        guard let data else {
            courses = nil
            weeklyCourses = nil
            semesterStartDate = nil
            realCurrentWeek = nil
            courseColors = [:]
            remarks = []
            return
        }

        courses = data.value.courses
        weeklyCourses = CourseScheduleUtil.getWeeklyCourses(data.value.courses)
        semesterStartDate = data.value.semesterStartDate
        realCurrentWeek = CourseScheduleUtil.getCurrentWeek(semesterStartDate: data.value.semesterStartDate, now: .now)
        courseColors = ColorUtil.getCourseColors(data.value.courses)
        remarks = data.value.remarks

        if let week = realCurrentWeek {
            withAnimation {
                currentWeek = week
            }
        }
    }

    private func addToCalendar(
        isFirstReminderEnabled: Bool,
        firstReminderOffset: CourseScheduleReminderOffset,
        isSecondReminderEnabled: Bool,
        secondReminderOffset: CourseScheduleReminderOffset
    ) async {
        guard !isCalendarExporting else { return }
        guard let courses, let semesterStartDate else {
            errorToast.show(message: "课表数据未加载，无法导出")
            return
        }

        isCalendarExporting = true
        loadingToast.show(message: "正在将课表添加到日历")
        defer {
            isCalendarExporting = false
            loadingToast.hide()
        }

        do {
            let dateRange = CourseScheduleUtil.getSemesterDateRange(semesterStartDate: semesterStartDate)
            let drafts = makeCalendarEventDrafts(
                courses: courses,
                semesterStartDate: semesterStartDate,
                isFirstReminderEnabled: isFirstReminderEnabled,
                firstReminderOffset: firstReminderOffset,
                isSecondReminderEnabled: isSecondReminderEnabled,
                secondReminderOffset: secondReminderOffset
            )

            let calendar = try await CalendarUtil.getOrCreateEventCalendar(named: "长理星球 - 课表")
            try await CalendarUtil.replaceEvents(
                calendar: calendar,
                from: dateRange.startDate,
                to: dateRange.endDate,
                with: drafts
            )

            successToast.show(message: "课表已成功添加到日历")
        } catch {
            errorToast.show(message: "导出失败: \(error.localizedDescription)")
        }
    }

    private func makeCalendarEventDrafts(
        courses: [EduHelper.Course],
        semesterStartDate: Date,
        isFirstReminderEnabled: Bool,
        firstReminderOffset: CourseScheduleReminderOffset,
        isSecondReminderEnabled: Bool,
        secondReminderOffset: CourseScheduleReminderOffset
    ) -> [CalendarEventDraft] {
        var alarmRelativeOffsets: [TimeInterval] = []
        if isFirstReminderEnabled {
            alarmRelativeOffsets.append(-firstReminderOffset.rawValue)
        }
        if isSecondReminderEnabled {
            alarmRelativeOffsets.append(-secondReminderOffset.rawValue)
        }

        var drafts: [CalendarEventDraft] = []
        for course in courses {
            for session in course.sessions {
                for week in session.weeks {
                    let dates = CourseScheduleUtil.getCourseEventDates(
                        session: session,
                        week: week,
                        semesterStartDate: semesterStartDate
                    )

                    var notes = "教师: \(course.teacher ?? "未知")"
                    if let groupName = course.groupName { notes += "\n组名: \(groupName)" }
                    notes += "\n周次: 第\(week)周"

                    drafts.append(
                        CalendarEventDraft(
                            title: course.courseName,
                            startDate: dates.startDate,
                            endDate: dates.endDate,
                            notes: notes,
                            location: session.classroom,
                            timeZone: CourseScheduleUtil.courseTimeZone,
                            alarmRelativeOffsets: alarmRelativeOffsets
                        )
                    )
                }
            }
        }
        return drafts
    }
}
