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

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isWideSize: Bool { sizeClass == .regular }

    private var colSpacing: CGFloat { isWideSize ? 4 : 2 }
    private var rowSpacing: CGFloat { isWideSize ? 4 : 2 }
    private var timeColWidth: CGFloat { isWideSize ? 50 : 30 }
    private var headerHeight: CGFloat { isWideSize ? 70 : 50 }
    private var sectionHeight: CGFloat { isWideSize ? 90 : 60 }

    private var horizontalPadding: CGFloat { 5 }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            topControlBar
            if let data = viewModel.courseScheduleData, !data.value.courses.isEmpty {
                #if os(macOS)
                HStack {
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

                    scrollView(data: data, weeklyCourses: viewModel.weeklyCourses)

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
                }
                #elseif os(iOS)
                scrollView(data: data, weeklyCourses: viewModel.weeklyCourses)
                #endif
            } else {
                ContentUnavailableView("暂无课表数据", systemImage: "doc.text.magnifyingglass", description: Text("当前筛选条件下没有找到课程"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .apply { view in
            if !isWideSize {
                view.sheet(isPresented: $viewModel.isCourseDetailPresented) {
                    sheetContentView
                }
            } else {
                view
                    .inspector(isPresented: .constant(true)) {
                        sheetContentView
                            #if os(macOS)
                        .inspectorColumnWidth(min: 200, ideal: 250, max: 300)
                            #elseif os(iOS)
                        .inspectorColumnWidth(min: 300, ideal: 400, max: 500)
                            #endif
                    }
            }
        }
        .onChange(of: !isWideSize) { _, usesSheet in
            viewModel.isCourseDetailPresented = usesSheet && viewModel.selectedCourseInfo != nil
        }
        .navigationTitle("我的课表")
        .navigationSubtitleCompat(viewModel.selectedSemester == nil ? "默认学期" : "学期" + (viewModel.selectedSemester ?? ""))
        .inlineToolbarTitle()
        .toolbar {
            ToolbarItemGroup(placement: .secondaryAction) {
                Button(action: { viewModel.isCustomizationManagementSheetPresented = true }) {
                    Label("自定义课程管理", systemImage: "slider.horizontal.3")
                }
                .disabled(viewModel.courseScheduleData == nil)

                Button(action: { viewModel.isSemestersSheetPresented = true }) {
                    Label("学期选择", systemImage: "calendar")
                }
                .disabled(viewModel.isSemestersLoading)

                Button(action: { viewModel.isCalendarSettingsSheetPresented = true }) {
                    Label("添加课表到系统日历", systemImage: "square.and.arrow.up")
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
        .task { await viewModel.loadInitial() }
        .errorToast($viewModel.errorToast)
        .loadingToast($viewModel.loadingToast)
        .successToast($viewModel.successToast)
        .sheet(isPresented: $viewModel.isCalendarSettingsSheetPresented) {
            CourseScheduleCalendarSettingsView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isSemestersSheetPresented) {
            CourseSemesterView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isCourseEditorSheetPresented) {
            CourseScheduleCustomCourseEditorView(
                viewModel: viewModel,
                editingCourse: viewModel.editingCustomCourse
            )
        }
        .sheet(isPresented: $viewModel.isCustomizationManagementSheetPresented) {
            CourseScheduleCustomizationManagementView(viewModel: viewModel)
        }
    }

    // MARK: - Sheet Content View

    @ViewBuilder
    var sheetContentView: some View {
        if let courseInfo = viewModel.selectedCourseInfo {
            CourseScheduleDetailView(
                course: courseInfo.course,
                session: courseInfo.session,
                isShowingToolbar: !isWideSize,
                showsCustomizationActions: true,
                isCustomCourse: {
                    if case .custom = courseInfo.source {
                        return true
                    }
                    return false
                }(),
                onHideOfficialCourse: {
                    viewModel.hideOfficialCourse(named: courseInfo.course.courseName)
                },
                onEditCustomCourse: {
                    if case .custom(let id) = courseInfo.source,
                        let customCourse = viewModel.customCourse(id: id)
                    {
                        viewModel.presentEditor(for: customCourse)
                        viewModel.isCourseDetailPresented = false
                    }
                },
                onDeleteCustomCourse: {
                    if case .custom(let id) = courseInfo.source {
                        viewModel.deleteCustomCourse(id: id)
                    }
                }
            )
        } else {
            ContentUnavailableView("请选择课程查看详情", systemImage: "doc.text.magnifyingglass")
        }
    }

    // MARK: - Top Control Bar

    @ViewBuilder
    private var topControlBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("今日 \(CourseScheduleUtil.dateFormatter.string(from: viewModel.today))")
                    .font(isWideSize ? .title3 : .headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                if #unavailable(iOS 26.0) {
                    Text(viewModel.selectedSemester ?? "默认学期")
                        .font(isWideSize ? .subheadline : .caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Picker("选择周数", selection: $viewModel.currentWeek.withAnimation()) {
                    ForEach(1...CourseScheduleUtil.weekCount, id: \.self) { week in
                        Text("第 \(week) 周").tag(week)
                    }
                }
                .fixedSize()

                Button(action: viewModel.goToCurrentWeek) {
                    Text("本周")
                        .fontWeight(.medium)
                }
                .disabled(viewModel.realCurrentWeek == nil || viewModel.currentWeek == viewModel.realCurrentWeek)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        #if os(iOS)
        .background(Color(PlatformColor.systemBackground))
        #endif
    }

    // MARK: - Horizontal Scroll View

    @ViewBuilder
    private func scrollView(data: Cached<CourseScheduleData>, weeklyCourses: [Int: [CourseDisplayInfo]]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(1...CourseScheduleUtil.weekCount, id: \.self) { week in
                    tableView(
                        for: week,
                        semesterStartDate: data.value.semesterStartDate,
                        weeklyCourses: weeklyCourses
                    )
                    .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(
            id: Binding<Int?>(
                get: { viewModel.currentWeek },
                set: { if let newWeek = $0 { viewModel.currentWeek = newWeek } }
            )
        )
    }

    // MARK: - Table View

    @ViewBuilder
    private func tableView(for week: Int, semesterStartDate: Date, weeklyCourses: [Int: [CourseDisplayInfo]]) -> some View {
        // 课表网格
        ScrollView {
            ZStack(alignment: .topLeading) {
                // 背景网格
                backgroundGridView

                // 课程视图
                coursesOverlayView(for: week, weeklyCourses: weeklyCourses)
            }
        }
        .safeAreaInset(edge: .top) {
            // 星期头部（日期和周几）
            headerView(for: week, semesterStartDate: semesterStartDate)
                .apply { view in
                    if #available(iOS 26.0, macOS 26.0, *) {
                        view
                            .background {
                                Rectangle()
                                    .fill(.clear)
                                    .glassEffect()
                                    .padding(.horizontal, 4)
                            }
                    } else {
                        view.background(.ultraThinMaterial)
                    }
                }
        }
    }

    // MARK: - Header View

    @ViewBuilder
    private func headerView(for week: Int, semesterStartDate: Date) -> some View {
        let dates = CourseScheduleUtil.getDatesForWeek(semesterStartDate: semesterStartDate, week: week)

        HStack(spacing: colSpacing) {
            // 左上角月份显示区
            VStack(alignment: .center, spacing: 0) {
                if let firstDate = dates.first {
                    Text(CourseScheduleUtil.monthFormatter.string(from: firstDate))
                        .font(.system(size: isWideSize ? 18 : 14, weight: .bold))
                    Text("月")
                        .font(.system(size: isWideSize ? 14 : 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: timeColWidth)

            // "周日" 到 "周六"
            ForEach(Array(zip(EduHelper.DayOfWeek.allCases, dates)), id: \.0) { day, date in
                let isToday = CourseScheduleUtil.isToday(date)
                VStack(spacing: 2) {
                    Text(day.stringValue)
                        .font(.system(size: isWideSize ? 15 : 11))
                        .foregroundColor(isToday ? .accentColor : .secondary)
                        .fontWeight(isToday ? .bold : .medium)

                    ZStack {
                        Circle()
                            .fill(isToday ? Color.accentColor : Color.clear)

                        Text(CourseScheduleUtil.dayFormatter.string(from: date))
                            .font(.system(size: isWideSize ? 18 : 14, weight: isToday ? .bold : .medium))
                            .foregroundColor(isToday ? .white : .primary)
                    }
                    .frame(width: isWideSize ? 36 : 26, height: isWideSize ? 36 : 26)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 6)
        .padding(.horizontal, horizontalPadding)
    }

    // MARK: - Background Grid View

    @ViewBuilder
    private var backgroundGridView: some View {
        HStack(spacing: colSpacing) {
            // 左侧时间列
            VStack(spacing: rowSpacing) {
                ForEach(1...10, id: \.self) { section in
                    VStack(spacing: 1) {
                        Text("\(section)")
                            .font(.system(size: isWideSize ? 18 : 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)

                        VStack(spacing: 0) {
                            Text(CourseScheduleUtil.sectionTimeString[section - 1].0)
                            Text(CourseScheduleUtil.sectionTimeString[section - 1].1)
                        }
                        .font(.system(size: isWideSize ? 12 : 9))
                        .foregroundColor(.secondary)
                    }
                    .frame(width: timeColWidth, height: sectionHeight)
                }
            }

            VStack(spacing: rowSpacing) {
                ForEach(1...10, id: \.self) { _ in
                    HStack(spacing: colSpacing) {
                        ForEach(1...7, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.primary.opacity(0.04))
                                .frame(height: sectionHeight)
                                .cornerRadius(isWideSize ? 8 : 4)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical)
    }

    // MARK: - Course Overlay View

    @ViewBuilder
    private func coursesOverlayView(for week: Int, weeklyCourses: [Int: [CourseDisplayInfo]]) -> some View {
        GeometryReader { geometry in
            // 通过减去水平内边距来计算实际内容宽度
            let contentWidth = geometry.size.width - (horizontalPadding * 2)

            // 正确计算间距的总宽度。8列之间有7个间隔
            let totalSpacingWidth = colSpacing * 7

            // 计算每一天列的最终宽度
            let dayColumnWidth = (contentWidth - timeColWidth - totalSpacingWidth) / 7

            ZStack(alignment: .topLeading) {
                if let coursesForWeek = weeklyCourses[week] {
                    let groupedCourses = Dictionary(grouping: coursesForWeek) { info in
                        "\(info.session.dayOfWeek.rawValue)-\(info.session.startSection)"
                    }

                    ForEach(Array(groupedCourses.values), id: \.first!.id) { group in
                        if let firstCourseInfo = group.first {
                            let courseHeight = calculateHeight(for: firstCourseInfo.session)
                            let xOffset = horizontalPadding + calculateXOffset(for: firstCourseInfo.session.dayOfWeek, columnWidth: dayColumnWidth)
                            let yOffset = calculateYOffset(for: firstCourseInfo.session)

                            if group.count == 1 {
                                // 正常课程
                                CourseCardView(course: firstCourseInfo.course, session: firstCourseInfo.session, color: viewModel.courseColors[firstCourseInfo.course.courseName] ?? .gray) {
                                    presentCourseDetail(firstCourseInfo)
                                }
                                .frame(width: dayColumnWidth, height: courseHeight)
                                .offset(x: xOffset, y: yOffset)
                            } else {
                                // 冲突课程
                                ConflictCourseCardView(courses: group, isPad: isWideSize) { selectedInfo in
                                    presentCourseDetail(selectedInfo)
                                }
                                .frame(width: dayColumnWidth, height: courseHeight)
                                .offset(x: xOffset, y: yOffset)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical)
    }
}

extension CourseScheduleView {
    private func presentCourseDetail(_ courseInfo: CourseDisplayInfo) {
        viewModel.selectedCourseInfo = courseInfo

        if !isWideSize {
            viewModel.isCourseDetailPresented = true
        }
    }

    // 计算课程卡片的高度
    func calculateHeight(for session: EduHelper.ScheduleSession) -> CGFloat {
        let sections = CGFloat(session.endSection - session.startSection + 1)
        return sections * sectionHeight + (sections - 1) * rowSpacing
    }

    // 计算课程卡片的 Y 轴偏移
    func calculateYOffset(for session: EduHelper.ScheduleSession) -> CGFloat {
        let y = CGFloat(session.startSection - 1)
        return y * sectionHeight + y * rowSpacing
    }

    // 计算课程卡片的 X 轴偏移
    func calculateXOffset(for day: EduHelper.DayOfWeek, columnWidth: CGFloat) -> CGFloat {
        let x = CGFloat(day.rawValue)
        return timeColWidth + colSpacing + (x * columnWidth) + (x * colSpacing)
    }
}
