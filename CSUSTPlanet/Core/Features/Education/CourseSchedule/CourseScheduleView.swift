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

    // MARK: - Body

    var body: some View {
        let isWideSize = (sizeClass == .regular)
        let layoutConfig = LayoutConfig(
            isWideSize: isWideSize,
            colSpacing: isWideSize ? 4 : 2,
            rowSpacing: isWideSize ? 4 : 2,
            horizontalPadding: 5,
            timeColWidth: isWideSize ? 50 : 30,
            sectionHeight: isWideSize ? 90 : 60
        )

        VStack(spacing: 0) {
            TopControlBarView(
                today: viewModel.today,
                selectedSemester: viewModel.selectedSemester,
                realCurrentWeek: viewModel.realCurrentWeek,
                currentWeek: $viewModel.currentWeek
            )

            if let data = viewModel.courseScheduleData, !data.value.courses.isEmpty {
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

                    ScrollTableView(
                        semesterStartDate: data.value.semesterStartDate,
                        weeklyCourses: viewModel.weeklyCourses,
                        courseColors: viewModel.courseColors,
                        currentWeek: $viewModel.currentWeek,
                        isCourseDetailPresented: $viewModel.isCourseDetailPresented,
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
        .environment(\.layoutConfig, layoutConfig)
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
                isShowingToolbar: !(sizeClass == .regular),
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
}

private struct LayoutConfig {
    let isWideSize: Bool
    let colSpacing: CGFloat
    let rowSpacing: CGFloat
    let horizontalPadding: CGFloat
    let timeColWidth: CGFloat
    let sectionHeight: CGFloat
}

private struct LayoutConfigKey: EnvironmentKey {
    static var defaultValue = LayoutConfig(
        isWideSize: false,
        colSpacing: 2,
        rowSpacing: 2,
        horizontalPadding: 8,
        timeColWidth: 30,
        sectionHeight: 60,
    )
}

extension EnvironmentValues {
    fileprivate var layoutConfig: LayoutConfig {
        get { self[LayoutConfigKey.self] }
        set { self[LayoutConfigKey.self] = newValue }
    }
}

// MARK: - TopControlBarView

private struct TopControlBarView: View {
    @Environment(\.layoutConfig) private var layoutConfig

    let today: Date
    let selectedSemester: String?
    let realCurrentWeek: Int?

    @Binding var currentWeek: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("今日 \(CourseScheduleUtil.dateFormatter.string(from: today))")
                    .font(layoutConfig.isWideSize ? .title3 : .headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                if #unavailable(iOS 26.0) {
                    Text(selectedSemester ?? "默认学期")
                        .font(layoutConfig.isWideSize ? .subheadline : .caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Picker("选择周数", selection: $currentWeek.withAnimation()) {
                    ForEach(1...CourseScheduleUtil.weekCount, id: \.self) { week in
                        Text("第 \(week) 周").tag(week)
                    }
                }
                .fixedSize()

                Button(action: {
                    withAnimation {
                        if let realWeek = realCurrentWeek, realWeek > 0 && realWeek <= CourseScheduleUtil.weekCount {
                            self.currentWeek = realWeek
                        } else {
                            self.currentWeek = 1
                        }
                    }
                }) {
                    Text("本周").fontWeight(.medium)
                }
                .disabled(realCurrentWeek == nil || currentWeek == realCurrentWeek)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        #if os(iOS)
        .background(Color(PlatformColor.systemBackground))
        #endif
    }
}

#Preview("TopControlBarView") {
    @Previewable @State var currentWeek = 8
    TopControlBarView(
        today: .now,
        selectedSemester: "2024-2025-1",
        realCurrentWeek: 16,
        currentWeek: $currentWeek
    )
}

// MARK: - HeaderView

private struct HeaderView: View {
    @Environment(\.layoutConfig) private var layoutConfig

    let semesterStartDate: Date
    let targetWeek: Int

    var body: some View {
        let dates = CourseScheduleUtil.getDatesForWeek(semesterStartDate: semesterStartDate, week: targetWeek)

        HStack(spacing: layoutConfig.colSpacing) {
            // 左上角月份显示区
            VStack(alignment: .center, spacing: 0) {
                if let firstDate = dates.first {
                    Text(CourseScheduleUtil.monthFormatter.string(from: firstDate))
                        .font(.system(size: layoutConfig.isWideSize ? 18 : 14, weight: .bold))
                    Text("月")
                        .font(.system(size: layoutConfig.isWideSize ? 14 : 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: layoutConfig.timeColWidth)

            // "周日" 到 "周六"
            ForEach(Array(zip(EduHelper.DayOfWeek.allCases, dates)), id: \.0) { day, date in
                let isToday = CourseScheduleUtil.isToday(date)
                VStack(spacing: 2) {
                    Text(day.stringValue)
                        .font(.system(size: layoutConfig.isWideSize ? 15 : 11))
                        .foregroundColor(isToday ? .accentColor : .secondary)
                        .fontWeight(isToday ? .bold : .medium)

                    ZStack {
                        Circle()
                            .fill(isToday ? Color.accentColor : Color.clear)

                        Text(CourseScheduleUtil.dayFormatter.string(from: date))
                            .font(.system(size: layoutConfig.isWideSize ? 18 : 14, weight: isToday ? .bold : .medium))
                            .foregroundColor(isToday ? .white : .primary)
                    }
                    .frame(width: layoutConfig.isWideSize ? 36 : 26, height: layoutConfig.isWideSize ? 36 : 26)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 6)
        .padding(.horizontal, layoutConfig.horizontalPadding)
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

#Preview("HeaderView") {
    HeaderView(
        semesterStartDate: .init(timeIntervalSince1970: 1_781_366_400),
        targetWeek: 1
    )
}

// MARK: - CourseOverlayView

private struct CourseOverlayView: View {
    @Environment(\.layoutConfig) private var layoutConfig

    let targetWeek: Int
    let weeklyCourses: [Int: [CourseDisplayInfo]]
    let courseColors: [String: Color]

    @Binding var isCourseDetailPresented: Bool
    @Binding var selectedCourseInfo: CourseDisplayInfo?

    var body: some View {
        GeometryReader { geometry in
            let contentWidth = geometry.size.width - (layoutConfig.horizontalPadding * 2)
            let totalSpacingWidth = layoutConfig.colSpacing * 7
            let dayColumnWidth = (contentWidth - layoutConfig.timeColWidth - totalSpacingWidth) / 7

            ZStack(alignment: .topLeading) {
                if let coursesForWeek = weeklyCourses[targetWeek] {
                    let groupedCourses = Dictionary(grouping: coursesForWeek) { info in
                        "\(info.session.dayOfWeek.rawValue)-\(info.session.startSection)"
                    }

                    ForEach(Array(groupedCourses.values), id: \.first!.id) { group in
                        if let firstCourseInfo = group.first {
                            let courseHeight = calculateHeight(for: firstCourseInfo.session)
                            let xOffset = layoutConfig.horizontalPadding + calculateXOffset(for: firstCourseInfo.session.dayOfWeek, columnWidth: dayColumnWidth)
                            let yOffset = calculateYOffset(for: firstCourseInfo.session)

                            if group.count == 1 {
                                // 正常课程
                                CourseCardView(course: firstCourseInfo.course, session: firstCourseInfo.session, color: courseColors[firstCourseInfo.course.courseName] ?? .gray) {
                                    presentCourseDetail(firstCourseInfo)
                                }
                                .frame(width: dayColumnWidth, height: courseHeight)
                                .offset(x: xOffset, y: yOffset)
                            } else {
                                // 冲突课程
                                ConflictCourseCardView(courses: group, isPad: layoutConfig.isWideSize) {
                                    presentCourseDetail($0)
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

    private func calculateHeight(for session: EduHelper.ScheduleSession) -> CGFloat {
        let sections = CGFloat(session.endSection - session.startSection + 1)
        return sections * layoutConfig.sectionHeight + (sections - 1) * layoutConfig.rowSpacing
    }

    private func calculateYOffset(for session: EduHelper.ScheduleSession) -> CGFloat {
        let y = CGFloat(session.startSection - 1)
        return y * layoutConfig.sectionHeight + y * layoutConfig.rowSpacing
    }

    private func calculateXOffset(for day: EduHelper.DayOfWeek, columnWidth: CGFloat) -> CGFloat {
        let x = CGFloat(day.rawValue)
        return layoutConfig.timeColWidth + layoutConfig.colSpacing + (x * columnWidth) + (x * layoutConfig.colSpacing)
    }

    private func presentCourseDetail(_ courseInfo: CourseDisplayInfo) {
        selectedCourseInfo = courseInfo
        if !layoutConfig.isWideSize {
            isCourseDetailPresented = true
        }
    }
}

#Preview("CourseOverlayView") {
    let sessionA1 = EduHelper.ScheduleSession(weeks: [1], startSection: 1, endSection: 2, dayOfWeek: .monday, classroom: "教室A1")
    let sessionA2 = EduHelper.ScheduleSession(weeks: [1], startSection: 5, endSection: 8, dayOfWeek: .tuesday, classroom: "教室A2")
    let sessionA3 = EduHelper.ScheduleSession(weeks: [1], startSection: 3, endSection: 4, dayOfWeek: .wednesday, classroom: "教室A3")
    let courseA = EduHelper.Course(courseName: "课程A", groupName: nil, teacher: "老师A", sessions: [sessionA1, sessionA2, sessionA3])

    let sessionB = EduHelper.ScheduleSession(weeks: [1], startSection: 5, endSection: 6, dayOfWeek: .wednesday, classroom: "教室B")
    let courseB = EduHelper.Course(courseName: "课程B", groupName: nil, teacher: "老师B", sessions: [sessionB])

    let courseC = EduHelper.Course(courseName: "课程C", groupName: nil, teacher: "老师C", sessions: [sessionA3])

    let weeklyCourses: [Int: [CourseDisplayInfo]] = [
        1: [
            CourseDisplayInfo(course: courseA, session: courseA.sessions[0]),
            CourseDisplayInfo(course: courseA, session: courseA.sessions[1]),
            CourseDisplayInfo(course: courseA, session: courseA.sessions[2]),
            CourseDisplayInfo(course: courseB, session: courseB.sessions[0]),
            CourseDisplayInfo(course: courseC, session: courseC.sessions[0]),  // 冲突
        ]
    ]

    let courseColors: [String: Color] = [
        "课程A": .blue,
        "课程B": .green,
        "课程C": .yellow,
    ]

    CourseOverlayView(
        targetWeek: 1,
        weeklyCourses: weeklyCourses,
        courseColors: courseColors,
        isCourseDetailPresented: .constant(false),
        selectedCourseInfo: .constant(nil)
    )
}

// MARK: - BackgroundGridView

private struct BackgroundGridView: View {
    @Environment(\.layoutConfig) private var layoutConfig

    var body: some View {
        HStack(spacing: layoutConfig.colSpacing) {
            // 左侧时间列
            VStack(spacing: layoutConfig.rowSpacing) {
                ForEach(1...10, id: \.self) { section in
                    VStack(spacing: 1) {
                        Text("\(section)")
                            .font(.system(size: layoutConfig.isWideSize ? 18 : 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)

                        VStack(spacing: 0) {
                            Text(CourseScheduleUtil.sectionTimeString[section - 1].0)
                            Text(CourseScheduleUtil.sectionTimeString[section - 1].1)
                        }
                        .font(.system(size: layoutConfig.isWideSize ? 12 : 9))
                        .foregroundColor(.secondary)
                    }
                    .frame(width: layoutConfig.timeColWidth, height: layoutConfig.sectionHeight)
                }
            }

            VStack(spacing: layoutConfig.rowSpacing) {
                ForEach(1...10, id: \.self) { _ in
                    HStack(spacing: layoutConfig.colSpacing) {
                        ForEach(1...7, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.primary.opacity(0.04))
                                .frame(height: layoutConfig.sectionHeight)
                                .cornerRadius(layoutConfig.isWideSize ? 8 : 4)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, layoutConfig.horizontalPadding)
        .padding(.vertical)
    }
}

#Preview("BackgroundGridView") {
    BackgroundGridView()
}

// MARK: TableView

private struct TableView: View {
    let semesterStartDate: Date
    let targetWeek: Int
    let weeklyCourses: [Int: [CourseDisplayInfo]]
    let courseColors: [String: Color]

    @Binding var isCourseDetailPresented: Bool
    @Binding var selectedCourseInfo: CourseDisplayInfo?

    var body: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                BackgroundGridView()
                CourseOverlayView(
                    targetWeek: targetWeek,
                    weeklyCourses: weeklyCourses,
                    courseColors: courseColors,
                    isCourseDetailPresented: $isCourseDetailPresented,
                    selectedCourseInfo: $selectedCourseInfo,
                )
            }
        }
        .safeAreaInset(edge: .top) {
            HeaderView(
                semesterStartDate: semesterStartDate,
                targetWeek: targetWeek
            )
        }
    }
}

#Preview("TableView") {
    TableView(
        semesterStartDate: .init(timeIntervalSince1970: 1_781_366_400),
        targetWeek: 1,
        weeklyCourses: [:],
        courseColors: [:],
        isCourseDetailPresented: .constant(false),
        selectedCourseInfo: .constant(nil)
    )
}

// MARK: - ScrollTableView

private struct ScrollTableView: View {
    let semesterStartDate: Date
    let weeklyCourses: [Int: [CourseDisplayInfo]]
    let courseColors: [String: Color]

    @Binding var currentWeek: Int
    @Binding var isCourseDetailPresented: Bool
    @Binding var selectedCourseInfo: CourseDisplayInfo?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(1...CourseScheduleUtil.weekCount, id: \.self) { week in
                    TableView(
                        semesterStartDate: semesterStartDate,
                        targetWeek: week,
                        weeklyCourses: weeklyCourses,
                        courseColors: courseColors,
                        isCourseDetailPresented: $isCourseDetailPresented,
                        selectedCourseInfo: $selectedCourseInfo
                    )
                    .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(
            id: Binding<Int?>(
                get: { currentWeek },
                set: { if let newWeek = $0 { currentWeek = newWeek } }
            )
        )
    }
}

#Preview("ScrollTableView") {
    ScrollTableView(
        semesterStartDate: .init(timeIntervalSince1970: 1_781_366_400),
        weeklyCourses: [:],
        courseColors: [:],
        currentWeek: .constant(1),
        isCourseDetailPresented: .constant(false),
        selectedCourseInfo: .constant(nil)
    )
}
