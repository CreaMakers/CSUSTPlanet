//
//  CourseScheduleView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import AlertToast
import CSUSTKit
import SwiftUI

struct CourseScheduleView: View {
    @State private var viewModel = CourseScheduleViewModel()

    @State private var isSemestersSheetPresented = false
    @State private var isCalendarSettingsSheetPresented = false
    @State private var isCourseDetailPresented = false

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
                selectedSemester: viewModel.selectedSemester,
                realCurrentWeek: viewModel.realCurrentWeek,
                currentWeek: $viewModel.currentWeek
            )

            if let data = viewModel.courseScheduleData, !data.value.courses.isEmpty {
                let weeklyCourses = CourseScheduleUtil.getWeeklyCourses(data.value.courses)

                HStack {
                    #if os(macOS)
                    Button(action: { viewModel.changeWeek(by: -1) }) {
                        GroupBox {
                            Image(systemName: "chevron.left")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(maxHeight: .infinity)
                                .frame(width: 32)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.currentWeek <= 1)
                    .keyboardShortcut(.leftArrow, modifiers: [])
                    #endif

                    CourseScheduleScrollTable(
                        semesterStartDate: data.value.semesterStartDate,
                        weeklyCourses: weeklyCourses,
                        courseColors: viewModel.courseColors,
                        currentWeek: $viewModel.currentWeek,
                        isCourseDetailPresented: $isCourseDetailPresented,
                        selectedCourseInfo: $viewModel.selectedCourseInfo
                    )

                    #if os(macOS)
                    Button(action: { viewModel.changeWeek(by: 1) }) {
                        GroupBox {
                            Image(systemName: "chevron.right")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(maxHeight: .infinity)
                                .frame(width: 32)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.currentWeek >= CourseScheduleUtil.weekCount)
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
                    sheetContentView
                }
            } else {
                view.inspector(isPresented: $isCourseDetailPresented) {
                    sheetContentView
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
        .navigationSubtitleCompat(viewModel.selectedSemester == nil ? "默认学期" : "学期" + (viewModel.selectedSemester ?? ""))
        .inlineToolbarTitle()
        .toolbar {
            ToolbarItemGroup(placement: .secondaryAction) {
                Button(action: { isSemestersSheetPresented = true }) {
                    Label("学期选择", systemImage: "gearshape")
                }
                .disabled(viewModel.isSemestersLoading)

                Button(action: { isCalendarSettingsSheetPresented = true }) {
                    Label("添加课表到系统日历", systemImage: "calendar.badge.plus")
                }
                .disabled(viewModel.isSemestersLoading || viewModel.courseScheduleData?.value.courses.isEmpty == true)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(asyncAction: viewModel.loadCourses) {
                    if viewModel.isCourseScheduleLoading {
                        ProgressView().smallControlSizeOnMac()
                    } else {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(viewModel.isCourseScheduleLoading)
            }
        }
        .onAppear {
            if isWideSize {
                isCourseDetailPresented = true
            }
        }
        .task { await viewModel.loadInitial() }
        .errorToast($viewModel.errorToast)
        .loadingToast($viewModel.loadingToast)
        .successToast($viewModel.successToast)
        .sheet(isPresented: $isCalendarSettingsSheetPresented) {
            CourseScheduleCalendarSettings(onAdd: viewModel.addToCalendar)
        }
        .sheet(isPresented: $isSemestersSheetPresented) {
            CourseScheduleSemesterSelect(
                selectedSemester: $viewModel.selectedSemester,
                availableSemesters: viewModel.availableSemesters,
                isLoading: viewModel.isSemestersLoading,
                onRefresh: viewModel.loadAvailableSemesters,
                onComplete: viewModel.loadCourses
            )
            .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    var sheetContentView: some View {
        if let courseInfo = viewModel.selectedCourseInfo {
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
