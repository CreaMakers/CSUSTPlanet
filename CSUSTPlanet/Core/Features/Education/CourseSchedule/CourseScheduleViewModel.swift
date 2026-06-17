//
//  CourseScheduleViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/18.
//

import CSUSTKit
import Combine
import EventKit
import Foundation
import SwiftUI

enum CalendarReminderOffset: TimeInterval, CaseIterable, Identifiable {
    case atTime = 0
    case fiveMinutes = 300
    case tenMinutes = 600
    case fifteenMinutes = 900
    case thirtyMinutes = 1800
    case oneHour = 3600

    var id: TimeInterval { rawValue }

    var title: String {
        switch self {
        case .atTime: return "事件发生时"
        case .fiveMinutes: return "提前 5 分钟"
        case .tenMinutes: return "提前 10 分钟"
        case .fifteenMinutes: return "提前 15 分钟"
        case .thirtyMinutes: return "提前 30 分钟"
        case .oneHour: return "提前 1 小时"
        }
    }
}

enum CalendarExportScope: Int, CaseIterable, Identifiable {
    case next1Week = 1
    case next2Weeks = 2
    case next3Weeks = 3
    case next4Weeks = 4
    case next5Weeks = 5

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .next1Week: return "未来 1 周"
        case .next2Weeks: return "未来 2 周"
        case .next3Weeks: return "未来 3 周"
        case .next4Weeks: return "未来 4 周"
        case .next5Weeks: return "未来 5 周"
        }
    }
}

@MainActor
@Observable
class CourseScheduleViewModel {
    var courseScheduleData: Cached<CourseScheduleData>? = nil
    var availableSemesters: [String] = []

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    var isCourseScheduleLoading: Bool = false
    var isSemestersLoading: Bool = false

    var isSemestersSheetPresented: Bool = false
    var isCalendarSettingsSheetPresented: Bool = false

    var isCourseDetailPresented: Bool = false

    // TabView显示的第几周
    var currentWeek: Int = 1
    var selectedSemester: String? = nil

    var selectedCourseInfo: CourseDisplayInfo?

    var courseColors: [String: Color] = [:]

    // 当日日期
    // #if DEBUG
    //     let today: Date = {
    //         let dateFormatter = DateFormatter()
    //         dateFormatter.dateFormat = "yyyy-MM-dd"
    //         // 调试时使用固定日期
    //         return dateFormatter.date(from: "2025-09-15")!
    //     }()
    // #else
    @ObservationIgnored let today: Date = .now
    // #endif

    // 当前日期在第几周
    var realCurrentWeek: Int? = nil

    var errorToast: ToastState = .errorTitle
    var loadingToast: ToastState = .init(title: "添加中")
    var successToast: ToastState = .init(title: "添加成功")

    @ObservationIgnored var isInitial: Bool = true

    var firstReminderOffset: CalendarReminderOffset = .tenMinutes
    var isFirstReminderEnabled: Bool = false

    var secondReminderOffset: CalendarReminderOffset = .atTime
    var isSecondReminderEnabled: Bool = false

    var exportScope: CalendarExportScope = .next1Week
    var isExportScopeLimited: Bool = false

    init() {
        applyCourseScheduleCache(MMKVHelper.CourseSchedule.cache)

        MMKVHelper.CourseSchedule.$cache
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.applyCourseScheduleCache(data)
            }
            .store(in: &cancellables)
    }

    func loadInitial() async {
        guard isInitial else { return }
        isInitial = false
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadAvailableSemesters() }
            group.addTask { await self.loadCourses() }
        }
    }

    func loadAvailableSemesters() async {
        guard !isSemestersLoading else { return }
        isSemestersLoading = true
        defer { isSemestersLoading = false }

        do {
            (availableSemesters, selectedSemester) = try await AuthManager.shared.withAuthRetry(system: .edu) {
                try await AuthManager.shared.eduHelper.courseService.getAvailableSemestersForCourseSchedule()
            }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func loadCourses() async {
        guard !isCourseScheduleLoading else { return }
        isCourseScheduleLoading = true
        defer { isCourseScheduleLoading = false }

        do {
            let courses = try await AuthManager.shared.withAuthRetry(system: .edu) {
                try await AuthManager.shared.eduHelper.courseService.getCourseSchedule(academicYearSemester: self.selectedSemester)
            }
            let semesterStartDate = try await AuthManager.shared.withAuthRetry(system: .edu) {
                try await AuthManager.shared.eduHelper.semesterService.getSemesterStartDate(academicYearSemester: self.selectedSemester)
            }
            let data = Cached<CourseScheduleData>(cachedAt: .now, value: CourseScheduleData(semester: selectedSemester, semesterStartDate: semesterStartDate, courses: courses))
            MMKVHelper.CourseSchedule.cache = data
            WidgetTimelineRefreshHelper.reloadCourseScheduleWidgets()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func applyCourseScheduleCache(_ data: Cached<CourseScheduleData>?) {
        courseScheduleData = data

        guard let data else {
            realCurrentWeek = nil
            courseColors = [:]
            currentWeek = 1
            return
        }

        updateSchedules(data.value.semesterStartDate, data.value.courses)
    }

    private func updateSchedules(_ semesterStartDate: Date, _ courses: [EduHelper.Course]) {
        self.realCurrentWeek = CourseScheduleUtil.getCurrentWeek(semesterStartDate: semesterStartDate, now: today)

        // 为每门课程分配颜色
        courseColors = ColorUtil.getCourseColors(courses)

        // 自动跳转到当前周
        if let week = realCurrentWeek {
            withAnimation {
                self.currentWeek = week
            }
        }
    }

    func goToCurrentWeek() {
        if let realWeek = realCurrentWeek, realWeek > 0 && realWeek <= CourseScheduleUtil.weekCount {
            withAnimation(.snappy(duration: 0.15, extraBounce: 0)) {
                self.currentWeek = realWeek
            }
        } else {
            withAnimation(.snappy(duration: 0.15, extraBounce: 0)) {
                self.currentWeek = 1
            }
        }
    }

    func changeWeek(by amount: Int) {
        let newWeek = currentWeek + amount
        if newWeek >= 1 && newWeek <= CourseScheduleUtil.weekCount {
            withAnimation(.snappy(duration: 0.15, extraBounce: 0)) {
                self.currentWeek = newWeek
            }
        }
    }

    func loadCalendarSettings() {
        if let firstOffset = MMKVHelper.CourseSchedule.CalendarSync.firstReminderOffset, let offset = CalendarReminderOffset(rawValue: firstOffset) {
            isFirstReminderEnabled = true
            firstReminderOffset = offset
        }

        if let secondOffset = MMKVHelper.CourseSchedule.CalendarSync.secondReminderOffset, let offset = CalendarReminderOffset(rawValue: secondOffset) {
            isSecondReminderEnabled = true
            secondReminderOffset = offset
        }

        if let scope = MMKVHelper.CourseSchedule.CalendarSync.exportScopeLimit, let scope = CalendarExportScope(rawValue: scope) {
            isExportScopeLimited = true
            exportScope = scope
        }
    }

    func addToCalendar() async {
        MMKVHelper.CourseSchedule.CalendarSync.firstReminderOffset = isFirstReminderEnabled ? firstReminderOffset.rawValue : nil
        MMKVHelper.CourseSchedule.CalendarSync.secondReminderOffset = isSecondReminderEnabled ? secondReminderOffset.rawValue : nil
        MMKVHelper.CourseSchedule.CalendarSync.exportScopeLimit = isExportScopeLimited ? exportScope.rawValue : nil

        guard let data = self.courseScheduleData?.value else {
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

            for course in data.courses {
                for session in course.sessions {
                    for week in session.weeks {
                        guard let dates = CourseScheduleUtil.getCourseEventDates(session: session, week: week, semesterStartDate: data.semesterStartDate) else { continue }
                        let eventStartDate = dates.startDate
                        let eventEndDate = dates.endDate

                        if isExportScopeLimited {
                            let expectedWeeks = exportScope.rawValue
                            let startOfToday = currentCalendar.startOfDay(for: Date())
                            let timeLimit = currentCalendar.date(byAdding: .day, value: expectedWeeks * 7, to: startOfToday)!
                            guard eventStartDate >= startOfToday && eventStartDate < timeLimit else { continue }
                        }

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

extension MMKVHelper.CourseSchedule {
    enum CalendarSync {
        @MMKVOptionalStorage(key: "CourseSchedule.CalendarSync.exportScopeLimit")
        static var exportScopeLimit: Int?

        @MMKVOptionalStorage(key: "CourseSchedule.CalendarSync.firstReminderOffset")
        static var firstReminderOffset: Double?

        @MMKVOptionalStorage(key: "CourseSchedule.CalendarSync.secondReminderOffset")
        static var secondReminderOffset: Double?
    }
}
