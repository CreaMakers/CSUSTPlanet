//
//  CourseScheduleView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import CSUSTKit
import SwiftUI

struct CourseScheduleView: View {
    @StateObject var viewModel: CourseScheduleViewModel

    init(authManager: AuthManager) {
        _viewModel = StateObject(wrappedValue: CourseScheduleViewModel(eduHelper: authManager.eduHelper))
    }

    var body: some View {
        VStack(spacing: 0) {
            topControlBar
            if viewModel.isCoursesLoading {
                VStack {
                    ProgressView("加载课程中...")
                }
                .padding()
                .frame(maxHeight: .infinity)
            } else if let semesterStartDate = viewModel.semesterStartDate {
                // 课表的每一周翻页
                TabView(selection: $viewModel.currentWeek) {
                    ForEach(1 ... viewModel.weekCount, id: \.self) { week in
                        tableView(for: week, semesterStartDate: semesterStartDate)
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        viewModel.loadCourses()
                    } label: {
                        Label("刷新课表", systemImage: "magnifyingglass")
                    }

                    Button {
                        viewModel.loadAvailableSemesters()
                    } label: {
                        Label("刷新可选学期列表", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Label("更多操作", systemImage: "ellipsis.circle")
                }
            }
        }
        .task {
            viewModel.loadAvailableSemesters()
            viewModel.loadCourses()
        }
        .alert("错误", isPresented: $viewModel.isShowingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - 顶部全局控制栏

    private var topControlBar: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(viewModel.formatDate(viewModel.today))
                    .font(.headline)
                    .foregroundColor(.primary)

                if let realCurrentWeek = viewModel.realCurrentWeek {
                    Text("第 \(viewModel.currentWeek) 周" + (viewModel.currentWeek == realCurrentWeek ? " (本周)" : ""))
                        .font(.subheadline)
                } else {
                    Text("第 \(viewModel.currentWeek) 周")
                        .font(.subheadline)
                }
            }

            Spacer()

            HStack {
                if viewModel.isSemestersLoading {
                    ProgressView("加载学期列表...")
                } else {
                    Picker("学期", selection: $viewModel.selectedSemester) {
                        Text("默认学期").tag(nil as String?)
                        ForEach(viewModel.availableSemesters, id: \.self) { semester in
                            Text(semester).tag(semester as String?)
                        }
                    }
                }

                Button(action: viewModel.goToCurrentWeek) {
                    Text("回到本周")
                }
                .disabled(viewModel.realCurrentWeek == nil)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - 单周课表页面

    private func tableView(for week: Int, semesterStartDate: Date) -> some View {
        VStack(spacing: 0) {
            // 星期头部（日期和周几）
            headerView(for: week, semesterStartDate: semesterStartDate)

            // 课表网格
            ScrollView {
                ZStack(alignment: .topLeading) {
                    // 背景网格
                    backgroundGrid

                    // 课程视图
                    coursesOverlay(for: week)
                }
            }
        }
    }

    // MARK: - 星期头部视图

    private func headerView(for week: Int, semesterStartDate: Date) -> some View {
        let dates = viewModel.getDatesForWeek(week, semesterStartDate: semesterStartDate)
        let monthString = dates.first?.formatted(.dateTime.month(.defaultDigits)) ?? ""

        return HStack(spacing: viewModel.colSpacing) {
            // 左上角月份显示区
            VStack {
                Text(monthString)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text("月")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .frame(width: viewModel.timeColWidth)

            // "周日" 到 "周六"
            ForEach(Array(zip(DayOfWeek.allCases, dates)), id: \.0) { day, date in
                VStack {
                    Text(viewModel.dayOfWeekToString(day))
                        .font(.subheadline)
                        .foregroundColor(Calendar.current.isDateInToday(date) ? .primary : .secondary)
                        .fontWeight(Calendar.current.isDateInToday(date) ? .bold : .regular)

                    Text(date.formatted(.dateTime.day()))
                        .font(.subheadline)
                        .foregroundColor(Calendar.current.isDateInToday(date) ? .primary : .secondary)
                        .fontWeight(Calendar.current.isDateInToday(date) ? .bold : .regular)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: viewModel.headerHeight)
        .padding(.horizontal, 5)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - 背景网格视图

    private var backgroundGrid: some View {
        HStack(spacing: viewModel.colSpacing) {
            // 左侧时间列
            VStack(spacing: viewModel.rowSpacing) {
                ForEach(1 ... 10, id: \.self) { section in
                    VStack {
                        Text("\(section)")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text(viewModel.sectionTime[section - 1].0)
                            .font(.system(size: 10))
                        Text(viewModel.sectionTime[section - 1].1)
                            .font(.system(size: 10))
                    }
                    .frame(width: viewModel.timeColWidth, height: viewModel.sectionHeight)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(5)
                }
            }

            // 右侧课程区域背景
            ForEach(DayOfWeek.allCases, id: \.self) { _ in
                VStack(spacing: viewModel.rowSpacing) {
                    ForEach(1 ... 5, id: \.self) { _ in
                        Rectangle()
                            .fill(Color(.secondarySystemBackground))
                            .frame(height: viewModel.sectionHeight * 2 + viewModel.rowSpacing)
                            .cornerRadius(5)
                    }
                }
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical)
    }

    // MARK: - 课程浮层视图

    private func coursesOverlay(for week: Int) -> some View {
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
                if let coursesForWeek = viewModel.weeklyCourses[week] {
                    ForEach(coursesForWeek) { courseInfo in
                        CourseCardView(course: courseInfo.course, session: courseInfo.session)
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

#Preview {
    NavigationStack {
        CourseScheduleView(authManager: AuthManager())
    }
}
