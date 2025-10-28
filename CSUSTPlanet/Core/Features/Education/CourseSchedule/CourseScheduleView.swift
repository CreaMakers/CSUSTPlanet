//
//  CourseScheduleView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import AlertToast
import CSUSTKit
import SwiftUI

// MARK: - CourseScheduleView

struct CourseScheduleView: View {
    @StateObject var viewModel = CourseScheduleViewModel()

    var body: some View {
        VStack(spacing: 0) {
            topControlBar
            if let courseScheduleData = viewModel.data {
                let weeklyCourses = CourseScheduleHelper.getWeeklyCourses(courseScheduleData.value.courses)

                // 课表的每一周翻页
                TabView(selection: $viewModel.currentWeek) {
                    ForEach(1...CourseScheduleHelper.weekCount, id: \.self) { week in
                        tableView(for: week, semesterStartDate: courseScheduleData.value.semesterStartDate, weeklyCourses: weeklyCourses)
                            .tag(week)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)

                    Text("暂无课表数据")
                        .font(.headline)

                    Text("当前学期未设置或课程数据加载失败，请尝试刷新课表或选择其他学期。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxHeight: .infinity)
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
                        .progressViewStyle(.circular)
                        .scaleEffect(0.9, anchor: .center)
                } else {
                    Button(action: viewModel.loadCourses) {
                        Label("刷新课表", systemImage: "arrow.clockwise")
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
    }

    // MARK: - 顶部全局控制栏

    @ViewBuilder
    private var topControlBar: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("今日 \(CourseScheduleHelper.dateFormatter.string(from: viewModel.today))")
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack {
                    Text(viewModel.selectedSemester ?? "默认学期")
                        .font(.subheadline)
                    if let realCurrentWeek = viewModel.realCurrentWeek {
                        Text(viewModel.currentWeek == realCurrentWeek ? " (本周)" : " (非本周)")
                            .font(.subheadline)
                    } else {
                        Text("(不在学期内)")
                            .font(.subheadline)
                    }
                }
            }

            Spacer()

            HStack {
                Picker(
                    "当前周",
                    selection: Binding(
                        get: { viewModel.currentWeek },
                        set: { newValue in withAnimation { viewModel.currentWeek = newValue } }
                    )
                ) {
                    ForEach(1...CourseScheduleHelper.weekCount, id: \.self) { week in
                        Text("第 \(week) 周").tag(week)
                    }
                }
                .pickerStyle(.menu)
                .fixedSize(horizontal: true, vertical: false)

                Button(action: viewModel.goToCurrentWeek) {
                    Text("本周")
                }
                .disabled(viewModel.realCurrentWeek == nil)
            }
        }
        .padding()
        .background(Color(.systemBackground))
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
        let dates = CourseScheduleHelper.getDatesForWeek(semesterStartDate: semesterStartDate, week: week)

        HStack(spacing: viewModel.colSpacing) {
            // 左上角月份显示区
            VStack {
                Text(CourseScheduleHelper.monthFormatter.string(from: dates.first ?? Date()))
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text("月")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .frame(width: viewModel.timeColWidth)

            // "周日" 到 "周六"
            ForEach(Array(zip(EduHelper.DayOfWeek.allCases, dates)), id: \.0) { day, date in
                VStack {
                    Text(day.stringValue)
                        .font(.subheadline)
                        .foregroundColor(CourseScheduleHelper.isToday(date) ? .primary : .secondary)
                        .fontWeight(CourseScheduleHelper.isToday(date) ? .bold : .regular)

                    Text(CourseScheduleHelper.dayFormatter.string(from: date))
                        .font(.subheadline)
                        .foregroundColor(CourseScheduleHelper.isToday(date) ? .primary : .secondary)
                        .fontWeight(CourseScheduleHelper.isToday(date) ? .bold : .regular)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: viewModel.headerHeight)
        .padding(.horizontal, 5)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - 背景网格视图

    @ViewBuilder
    private var backgroundGrid: some View {
        HStack(spacing: viewModel.colSpacing) {
            // 左侧时间列
            VStack(spacing: viewModel.rowSpacing) {
                ForEach(1...10, id: \.self) { section in
                    VStack {
                        Text("\(section)")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text(CourseScheduleHelper.sectionTimeString[section - 1].0)
                            .font(.system(size: 10))
                        Text(CourseScheduleHelper.sectionTimeString[section - 1].1)
                            .font(.system(size: 10))
                    }
                    .frame(width: viewModel.timeColWidth, height: viewModel.sectionHeight)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(5)
                }
            }

            // 右侧课程区域背景
            // ForEach(EduHelper.DayOfWeek.allCases, id: \.self) { _ in
            //     VStack(spacing: viewModel.rowSpacing) {
            //         ForEach(1...5, id: \.self) { _ in
            //             Rectangle()
            //                 .fill(Color(.secondarySystemBackground))
            //                 .frame(height: viewModel.sectionHeight * 2 + viewModel.rowSpacing)
            //                 .cornerRadius(5)
            //         }
            //     }
            // }
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
            let totalSpacingWidth = viewModel.colSpacing * 7

            // 计算每一天列的最终宽度
            let dayColumnWidth = (contentWidth - viewModel.timeColWidth - totalSpacingWidth) / 7

            ZStack(alignment: .topLeading) {
                if let coursesForWeek = weeklyCourses[week] {
                    ForEach(coursesForWeek) { courseInfo in
                        CourseCardView(course: courseInfo.course, session: courseInfo.session, color: viewModel.courseColors[courseInfo.course.courseName] ?? .gray)
                            .frame(width: dayColumnWidth)
                            .frame(height: viewModel.calculateHeight(for: courseInfo.session))
                            .offset(
                                // 应用初始内边距到 x 偏移量以对齐坐标系
                                x: horizontalPadding + viewModel.calculateXOffset(for: courseInfo.session.dayOfWeek, columnWidth: dayColumnWidth),
                                y: viewModel.calculateYOffset(for: courseInfo.session)
                            )
                    }
                }
            }
        }
        .padding(.vertical)
    }
}
