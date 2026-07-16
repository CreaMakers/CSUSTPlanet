//
//  CourseScheduleContent.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/6/18.
//

import SwiftUI

struct CourseScheduleContent: View {
    @State private var isSemestersSheetPresented: Bool = false
    @State private var isCalendarSettingsSheetPresented = false
    @State private var isCourseDetailPresented = false
    @State private var selectedCourseInfo: CourseDisplayInfo?

    let weeklyCourses: [Int: [CourseDisplayInfo]]?
    let courseColors: [String: Color]
    let semesterStartDate: Date?
    let remarks: [String]

    let selectedSemester: String?

    let isCourseScheduleLoading: Bool

    @Binding var currentWeek: Int
    let realCurrentWeek: Int?

    @Binding var errorToast: ToastState
    @Binding var loadingToast: ToastState
    @Binding var successToast: ToastState

    var onRefreshCourses: () async -> Void
    var onSelectSemester: (String?) async -> Void
    var onAddCalendar: (Bool, CourseScheduleReminderOffset, Bool, CourseScheduleReminderOffset) async -> Void

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
                remarks: remarks,
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
                view.sheet(item: $selectedCourseInfo) { courseInfo in
                    CourseScheduleDetailView(
                        course: courseInfo.course,
                        session: courseInfo.session,
                        isToolbarPresented: sizeClass == .compact,
                    )
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
        .navigationSubtitleCompat(selectedSemester.map { "学期\($0)" } ?? "默认学期")
        .inlineToolbarTitle()
        .toolbar {
            ToolbarItemGroup(placement: .secondaryAction) {
                Button(action: { isSemestersSheetPresented = true }) {
                    Label("学期选择", systemImage: "gearshape")
                }

                Button(action: { isCalendarSettingsSheetPresented = true }) {
                    Label("添加课表到系统日历", systemImage: "calendar.badge.plus")
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button(asyncAction: onRefreshCourses) {
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
        .errorToast($errorToast)
        .loadingToast($loadingToast)
        .successToast($successToast)
        .sheet(isPresented: $isCalendarSettingsSheetPresented) {
            CourseScheduleCalendarSettings(onAdd: onAddCalendar)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isSemestersSheetPresented) {
            CourseScheduleSemesterSelect(onComplete: onSelectSemester)
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
}

#Preview("CourseScheduleContent") {
    NavigationStack {
        CourseScheduleContent(
            weeklyCourses: [:],
            courseColors: [:],
            semesterStartDate: nil,
            remarks: [],
            selectedSemester: nil,
            isCourseScheduleLoading: false,
            currentWeek: .constant(1),
            realCurrentWeek: 1,
            errorToast: .constant(.errorTitle),
            loadingToast: .constant(.loadingTitle),
            successToast: .constant(.successTitle),
            onRefreshCourses: {},
            onSelectSemester: { _ in },
            onAddCalendar: { _, _, _, _ in }
        )
    }
}
