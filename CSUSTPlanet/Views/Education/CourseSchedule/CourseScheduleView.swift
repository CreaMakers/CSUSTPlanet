//
//  CourseScheduleView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import CSUSTKit
import SwiftUI

struct CourseScheduleView: View {
    @StateObject var viewModel = CourseScheduleViewModel()

    var body: some View {
        VStack(spacing: 0) {
            topControlBar

            // 课表的每一周翻页
            TabView(selection: $viewModel.currentWeek) {
                ForEach(1 ... viewModel.weekCount, id: \.self) { week in
                    tableView(for: week)
                        .tag(week)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("我的课表")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 顶部全局控制栏

    private var topControlBar: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(viewModel.today, style: .date)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("第 \(viewModel.currentWeek) 周" + (viewModel.currentWeek == viewModel.realCurrentWeek ? " (本周)" : ""))
                    .font(.subheadline)
            }

            Spacer()

            HStack {
                Button(action: viewModel.goToCurrentWeek) {
                    Text("回到本周")
                }

                Button(action: {}) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - 单周课表页面

    private func tableView(for week: Int) -> some View {
        VStack(spacing: 0) {
            // 星期头部（日期和周几）
            headerView(for: week)

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

    private func headerView(for week: Int) -> some View {
        let dates = viewModel.getDatesForWeek(week)
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
                    ForEach(1 ... 10, id: \.self) { _ in
                        Rectangle()
                            .fill(Color(.secondarySystemBackground))
                            .frame(height: viewModel.sectionHeight)
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
            let dayColumnWidth = (geometry.size.width - viewModel.timeColWidth - (viewModel.colSpacing * 8)) / 7

            ZStack(alignment: .topLeading) {
                ForEach(viewModel.courses) { course in
                    ForEach(course.sessions) { session in
                        // 检查课程是否在本周
                        if session.weeks.contains(week) {
                            CourseCardView(course: course, session: session)
                                .frame(width: dayColumnWidth)
                                .frame(height: viewModel.calculateHeight(for: session))
                                .offset(
                                    x: viewModel.calculateXOffset(for: session.dayOfWeek, columnWidth: dayColumnWidth),
                                    y: viewModel.calculateYOffset(for: session)
                                )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical)
    }
}

#Preview {
    NavigationStack {
        CourseScheduleView()
    }
}
