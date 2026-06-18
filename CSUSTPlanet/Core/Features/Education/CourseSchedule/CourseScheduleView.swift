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

    @State private var availableSemesters: [String] = []
    @State private var selectedSemester: String? = nil

    @State private var isCourseScheduleLoading: Bool = false
    @State private var isSemestersLoading: Bool = false

    @State private var currentWeek: Int = 1
    @State private var realCurrentWeek: Int? = nil

    @State private var errorToast: ToastState = .errorTitle
    @State private var loadingToast: ToastState = .init(title: "添加中")
    @State private var successToast: ToastState = .init(title: "添加成功")

    @State private var isInitial: Bool = true

    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        let isWideSize = (sizeClass == .regular)
        let layoutConfig = CourseScheduleLayoutConfig(
            isWideSize: isWideSize,
            colSpacing: isWideSize ? 4 : 2,
            rowSpacing: isWideSize ? 4 : 2,
            horizontalPadding: 5,
            timeColWidth: isWideSize ? 50 : 30,
            sectionHeight: isWideSize ? 90 : 60
        )

        VStack(spacing: 0) {
            CourseScheduleControlBar(
                selectedSemester: selectedSemester,
                realCurrentWeek: realCurrentWeek,
                currentWeek: $currentWeek
            )

            if let weeklyCourses = weeklyCourses,
                let semesterStartDate = semesterStartDate
            {
                HStack {
                    #if os(macOS)
                    Button {
                        let newWeek = currentWeek - 1
                        if newWeek >= 1 && newWeek <= CourseScheduleUtil.weekCount {
                            withAnimation {
                                currentWeek = newWeek
                            }
                        }
                    } label: {
                        GroupBox {
                            Image(systemName: "chevron.left")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(maxHeight: .infinity)
                                .frame(width: 32)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(currentWeek <= 1)
                    .keyboardShortcut(.leftArrow, modifiers: [])
                    #endif

                    CourseScheduleScrollTable(
                        semesterStartDate: semesterStartDate,
                        weeklyCourses: weeklyCourses,
                        courseColors: courseColors,
                        currentWeek: $currentWeek,
                        isCourseDetailPresented: $isCourseDetailPresented,
                        selectedCourseInfo: $selectedCourseInfo
                    )

                    #if os(macOS)
                    Button {
                        let newWeek = currentWeek + 1
                        if newWeek >= 1 && newWeek <= CourseScheduleUtil.weekCount {
                            withAnimation {
                                currentWeek = newWeek
                            }
                        }
                    } label: {
                        GroupBox {
                            Image(systemName: "chevron.right")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(maxHeight: .infinity)
                                .frame(width: 32)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(currentWeek >= CourseScheduleUtil.weekCount)
                    .keyboardShortcut(.rightArrow, modifiers: [])
                    #endif
                }
            } else {
                ContentUnavailableView("暂无课表数据", systemImage: "doc.text.magnifyingglass", description: Text("当前筛选条件下没有找到课程"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .environment(\.courseScheduleLayoutConfig, layoutConfig)
        .apply { view in
            if !isWideSize {
                view.sheet(isPresented: $isCourseDetailPresented) {
                    sheetContent
                }
            } else {
                view.inspector(isPresented: $isCourseDetailPresented) {
                    sheetContent
                        #if os(macOS)
                    .inspectorColumnWidth(min: 200, ideal: 250, max: 300)
                        #elseif os(iOS)
                    .inspectorColumnWidth(min: 300, ideal: 400, max: 500)
                        #endif
                }
            }
        }
        .onChange(of: isWideSize) { _, isWideSize in
            if isWideSize {
                Task { @MainActor in
                    isCourseDetailPresented = true
                }
            }
        }
        .navigationTitle("我的课表")
        .navigationSubtitleCompat(selectedSemester == nil ? "默认学期" : "学期" + (selectedSemester ?? ""))
        .inlineToolbarTitle()
        .toolbar {
            ToolbarItemGroup(placement: .secondaryAction) {
                Button(action: { isSemestersSheetPresented = true }) {
                    Label("学期选择", systemImage: "gearshape")
                }
                .disabled(isSemestersLoading)

                Button(action: { isCalendarSettingsSheetPresented = true }) {
                    Label("添加课表到系统日历", systemImage: "calendar.badge.plus")
                }
                .disabled(isSemestersLoading)
            }

            ToolbarItem(placement: .primaryAction) {
                Button(asyncAction: loadCourses) {
                    if isCourseScheduleLoading {
                        ProgressView().smallControlSizeOnMac()
                    } else {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(isCourseScheduleLoading)
            }
        }
        .onAppear {
            if isWideSize {
                isCourseDetailPresented = true
            }
        }
        .onReceive(MMKVHelper.CourseSchedule.$cache.receive(on: RunLoop.main)) { data in
            applyCourseScheduleCache(data)
        }
        .task { await loadInitial() }
        .errorToast($errorToast)
        .loadingToast($loadingToast)
        .successToast($successToast)
        .sheet(isPresented: $isCalendarSettingsSheetPresented) {
            CourseScheduleCalendarSettings(onAdd: addToCalendar)
        }
        .sheet(isPresented: $isSemestersSheetPresented) {
            CourseScheduleSemesterSelect(
                selectedSemester: $selectedSemester,
                availableSemesters: availableSemesters,
                isLoading: isSemestersLoading,
                onRefresh: loadAvailableSemesters,
                onComplete: loadCourses
            )
            .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    var sheetContent: some View {
        if let courseInfo = selectedCourseInfo {
            CourseScheduleDetailView(
                course: courseInfo.course,
                session: courseInfo.session,
                isToolbarPresented: sizeClass == .compact,
            )
        } else {
            ContentUnavailableView("请选择课程查看详情", systemImage: "doc.text.magnifyingglass")
        }
    }

    private func loadInitial() async {
        guard isInitial else { return }
        isInitial = false
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadAvailableSemesters() }
            group.addTask { await self.loadCourses() }
        }
    }

    private func loadCourses() async {
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

    private func loadAvailableSemesters() async {
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

    private func applyCourseScheduleCache(_ data: Cached<CourseScheduleData>?) {
        guard let data else {
            realCurrentWeek = nil
            courseColors = [:]
            currentWeek = 1
            return
        }

        courses = data.value.courses
        weeklyCourses = CourseScheduleUtil.getWeeklyCourses(data.value.courses)
        semesterStartDate = data.value.semesterStartDate
        realCurrentWeek = CourseScheduleUtil.getCurrentWeek(semesterStartDate: data.value.semesterStartDate, now: .now)
        courseColors = ColorUtil.getCourseColors(data.value.courses)

        if let week = realCurrentWeek {
            withAnimation {
                self.currentWeek = week
            }
        }
    }

    private func addToCalendar(isFirstReminderEnabled: Bool, firstReminderOffset: CourseScheduleReminderOffset, isSecondReminderEnabled: Bool, secondReminderOffset: CourseScheduleReminderOffset) async {
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
