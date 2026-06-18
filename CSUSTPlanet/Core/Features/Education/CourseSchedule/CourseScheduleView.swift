//
//  CourseScheduleView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import AlertToast
import CSUSTKit
import EventKit
import SwiftUI

struct CourseScheduleView: View {
    @State private var isSemestersSheetPresented = false
    @State private var isCalendarSettingsSheetPresented = false

    @State private var isCourseDetailPresented = false
    @State private var selectedCourseInfo: CourseDisplayInfo?

    @State private var courses: [EduHelper.Course]? = nil
    @State private var weeklyCourses: [Int: [CourseDisplayInfo]]? = nil
    @State private var courseColors: [String: Color] = [:]
    @State private var semesterStartDate: Date? = nil
    @State private var remarks: [String] = []

    @State private var selectedSemester: String? = nil

    @State private var isCourseScheduleLoading: Bool = false
    @State private var isSemestersLoading: Bool = false

    @State private var currentWeek: Int = 1
    @State private var realCurrentWeek: Int? = nil

    @State private var errorToast: ToastState = .errorTitle
    @State private var loadingToast: ToastState = .loadingTitle
    @State private var successToast: ToastState = .successTitle

    @State private var isInitial: Bool = true

    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        CourseScheduleContent(
            isSemestersSheetPresented: $isSemestersSheetPresented,
            isCalendarSettingsSheetPresented: $isCalendarSettingsSheetPresented,
            isCourseDetailPresented: $isCourseDetailPresented,
            selectedCourseInfo: $selectedCourseInfo,
            weeklyCourses: weeklyCourses,
            courseColors: courseColors,
            semesterStartDate: semesterStartDate,
            remarks: remarks,
            selectedSemester: selectedSemester,
            isSemestersLoading: isSemestersLoading,
            isCourseScheduleLoading: isCourseScheduleLoading,
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
            let semesterStartDate = try await AuthManager.shared.withAuthRetry(system: .edu) {
                try await AuthManager.shared.eduHelper.semesterService.getSemesterStartDate(academicYearSemester: selectedSemester)
            }

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
        guard let courses, let semesterStartDate else {
            errorToast.show(message: "课表数据未加载，无法导出")
            return
        }

        loadingToast.show(message: "正在将课表添加到日历")
        defer { loadingToast.hide() }

        do {
            let currentCalendar = Calendar.current

            let calendar = try await CalendarUtil.getOrCreateEventCalendar(named: "长理星球 - 课表")
            let clearStartDate = currentCalendar.date(byAdding: .year, value: -1, to: Date())!
            let clearEndDate = currentCalendar.date(byAdding: .year, value: 1, to: Date())!

            try await CalendarUtil.clearCalendar(calendar: calendar, from: clearStartDate, to: clearEndDate)

            for course in courses {
                for session in course.sessions {
                    for week in session.weeks {
                        guard let dates = CourseScheduleUtil.getCourseEventDates(session: session, week: week, semesterStartDate: semesterStartDate) else { continue }
                        let eventStartDate = dates.startDate
                        let eventEndDate = dates.endDate

                        // 与课程相关的备注信息
                        var notes = "教师: \(course.teacher ?? "未知")"
                        if let groupName = course.groupName { notes += "\n组名: \(groupName)" }
                        notes += "\n周次: 第\(week)周"

                        var eventAlarms: [EKAlarm] = []
                        if isFirstReminderEnabled {
                            eventAlarms.append(EKAlarm(relativeOffset: -firstReminderOffset.rawValue))
                        }
                        if isSecondReminderEnabled {
                            eventAlarms.append(EKAlarm(relativeOffset: -secondReminderOffset.rawValue))
                        }

                        try await CalendarUtil.addEvent(
                            calendar: calendar,
                            title: course.courseName,
                            startDate: eventStartDate,
                            endDate: eventEndDate,
                            notes: notes,
                            location: session.classroom,
                            alarms: eventAlarms.isEmpty ? nil : eventAlarms,
                            // 这里连续提交会有性能问题，所以这里不提交改变
                            commit: false,
                            skipDuplicateCheck: true
                        )
                    }
                }
            }

            // 最后统一提交改变
            try CalendarUtil.commitChanges()

            successToast.show(message: "课表已成功添加到日历")
        } catch {
            errorToast.show(message: "导出失败: \(error.localizedDescription)")
        }
    }
}
