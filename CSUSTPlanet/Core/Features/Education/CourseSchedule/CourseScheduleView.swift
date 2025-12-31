//
//  CourseScheduleView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import AlertToast
import CSUSTKit
import InjectHotReload
import SwiftUI

// MARK: - CourseScheduleView

struct CourseScheduleView: View {
    @ObserveInjection var inject

    @StateObject var viewModel = CourseScheduleViewModel()

    let colSpacing: CGFloat = 2  // 列间距
    let rowSpacing: CGFloat = 2  // 行间距
    let timeColWidth: CGFloat = 30  // 左侧时间列宽度
    let headerHeight: CGFloat = 50  // 顶部日期行的高度
    let sectionHeight: CGFloat = 60  // 单个课程格子的高度

    var body: some View {
        VStack(spacing: 0) {
            topControlBar
            if let courseScheduleData = viewModel.data {
                let weeklyCourses = CourseScheduleUtil.getWeeklyCourses(courseScheduleData.value.courses)

                // 课表的每一周翻页
                TabView(selection: $viewModel.currentWeek) {
                    ForEach(1...CourseScheduleUtil.weekCount, id: \.self) { week in
                        tableView(for: week, semesterStartDate: courseScheduleData.value.semesterStartDate, weeklyCourses: weeklyCourses)
                            .tag(week)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea(.container, edges: .bottom)
            } else {
                emptyStateView
            }
        }
        .navigationTitle("我的课表")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { viewModel.isShowingSemestersSheet = true }) {
                    Image(systemName: "calendar")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Button(action: viewModel.loadCourses) {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        .task { viewModel.task() }
        .toast(isPresenting: $viewModel.isShowingWarning) {
            AlertToast(displayMode: .banner(.slide), type: .systemImage("exclamationmark.triangle", .yellow), title: "警告", subTitle: viewModel.warningMessage)
        }
        .toast(isPresenting: $viewModel.isShowingError) {
            AlertToast(type: .error(.red), title: "错误", subTitle: viewModel.errorMessage)
        }
        .sheet(isPresented: $viewModel.isShowingSemestersSheet) {
            CourseSemesterView()
                .environmentObject(viewModel)
        }
        .enableInjection()
        .trackView("CourseSchedule")
    }

    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("暂无课表数据")
                .font(.headline)
            Text("当前学期未设置或数据加载失败")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - 顶部全局控制栏

    @ViewBuilder
    private var topControlBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("今日 \(CourseScheduleUtil.dateFormatter.string(from: viewModel.today))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Text(viewModel.selectedSemester ?? "默认学期")
                    if viewModel.realCurrentWeek == nil {
                        Text("• 非学期内")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Menu {
                    ForEach(1...CourseScheduleUtil.weekCount, id: \.self) { week in
                        Button("第 \(week) 周") {
                            withAnimation { viewModel.currentWeek = week }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("第 \(viewModel.currentWeek) 周")
                            .fontWeight(.medium)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }

                Button(action: viewModel.goToCurrentWeek) {
                    Text("本周")
                        .fontWeight(.medium)
                }
                .disabled(viewModel.realCurrentWeek == nil || viewModel.currentWeek == viewModel.realCurrentWeek)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            Divider().opacity(0.6),
            alignment: .bottom
        )
    }

    // MARK: - 单周课表页面

    @ViewBuilder
    private func tableView(for week: Int, semesterStartDate: Date, weeklyCourses: [Int: [CourseDisplayInfo]]) -> some View {
        VStack(spacing: 0) {
            // 星期头部（日期和周几）
            headerView(for: week, semesterStartDate: semesterStartDate)

            // 课表网格
            ScrollView {
                ZStack(alignment: .topLeading) {
                    // 背景网格
                    backgroundGrid

                    // 课程视图
                    coursesOverlay(for: week, weeklyCourses: weeklyCourses)
                }
            }
        }
    }

    // MARK: - 星期头部视图

    @ViewBuilder
    private func headerView(for week: Int, semesterStartDate: Date) -> some View {
        let dates = CourseScheduleUtil.getDatesForWeek(semesterStartDate: semesterStartDate, week: week)

        HStack(spacing: colSpacing) {
            // 左上角月份显示区
            VStack(alignment: .center, spacing: 0) {
                if let firstDate = dates.first {
                    Text(CourseScheduleUtil.monthFormatter.string(from: firstDate))
                        .font(.system(size: 14, weight: .bold))
                    Text("月")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: timeColWidth)

            // "周日" 到 "周六"
            ForEach(Array(zip(EduHelper.DayOfWeek.allCases, dates)), id: \.0) { day, date in
                let isToday = CourseScheduleUtil.isToday(date)
                VStack(spacing: 2) {
                    Text(day.stringValue)
                        .font(.system(size: 11))
                        .foregroundColor(isToday ? .accentColor : .secondary)
                        .fontWeight(isToday ? .bold : .medium)

                    ZStack {
                        Circle()
                            .fill(isToday ? Color.accentColor : Color.clear)

                        Text(CourseScheduleUtil.dayFormatter.string(from: date))
                            .font(.system(size: 14, weight: isToday ? .bold : .medium))
                            .foregroundColor(isToday ? .white : .primary)
                    }
                    .frame(width: 26, height: 26)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 6)
        .padding(.horizontal, 5)
        .background(Color(.systemBackground))
    }

    // MARK: - 背景网格视图

    @ViewBuilder
    private var backgroundGrid: some View {
        HStack(spacing: colSpacing) {
            // 左侧时间列
            VStack(spacing: rowSpacing) {
                ForEach(1...10, id: \.self) { section in
                    VStack(spacing: 1) {
                        Text("\(section)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)

                        VStack(spacing: 0) {
                            Text(CourseScheduleUtil.sectionTimeString[section - 1].0)
                            Text(CourseScheduleUtil.sectionTimeString[section - 1].1)
                        }
                        .font(.system(size: 9))
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
                                .fill(Color(.secondarySystemBackground).opacity(0.3))
                                .frame(height: sectionHeight)
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical)
    }

    // MARK: - 课程浮层视图

    @ViewBuilder
    private func coursesOverlay(for week: Int, weeklyCourses: [Int: [CourseDisplayInfo]]) -> some View {
        GeometryReader { geometry in
            // 计算每日的列宽
            let horizontalPadding: CGFloat = 5

            // 通过减去水平内边距来计算实际内容宽度
            let contentWidth = geometry.size.width - (horizontalPadding * 2)

            // 正确计算间距的总宽度。8列之间有7个间隔
            let totalSpacingWidth = colSpacing * 7

            // 计算每一天列的最终宽度
            let dayColumnWidth = (contentWidth - timeColWidth - totalSpacingWidth) / 7

            ZStack(alignment: .topLeading) {
                if let coursesForWeek = weeklyCourses[week] {
                    ForEach(coursesForWeek) { courseInfo in
                        CourseCardView(course: courseInfo.course, session: courseInfo.session, color: viewModel.courseColors[courseInfo.course.courseName] ?? .gray)
                            .frame(width: dayColumnWidth)
                            .frame(height: calculateHeight(for: courseInfo.session))
                            .offset(
                                // 应用初始内边距到 x 偏移量以对齐坐标系
                                x: horizontalPadding + calculateXOffset(for: courseInfo.session.dayOfWeek, columnWidth: dayColumnWidth),
                                y: calculateYOffset(for: courseInfo.session)
                            )
                    }
                }
            }
        }
        .padding(.vertical)
    }
}

extension CourseScheduleView {
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
