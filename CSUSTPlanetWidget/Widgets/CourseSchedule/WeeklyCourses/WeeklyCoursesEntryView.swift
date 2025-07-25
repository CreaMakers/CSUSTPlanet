//
//  WeeklyCoursesEntryView.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/7/25.
//

import CSUSTKit
import SwiftUI
import WidgetKit

func mockWeeklyCoursesEntry() -> WeeklyCoursesEntry {
    let semesterDateFormatter = DateFormatter()
    semesterDateFormatter.dateFormat = "yyyy-MM-dd"

    let data = CourseScheduleData.fromCourses(courses: courses, semester: "2025-2026-1", semesterStartDate: semesterDateFormatter.date(from: "2025-09-07")!)

    let timeDateFormatter = DateFormatter()
    timeDateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

    return WeeklyCoursesEntry(
        date: timeDateFormatter.date(from: "2025-09-21 17:55")!,
        configuration: WeeklyCoursesIntent(),
        data: data
    )
}

struct WeeklyCoursesEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily

    var entry: WeeklyCoursesProvider.Entry

    var body: some View {
        if let data = entry.data {
            VStack {
                HStack {
                    Text("本周课程")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(data.semester ?? "默认学期")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    Text(ScheduleHelper.getWeekday(from: entry.date))
                        .font(.system(size: 14))
                        .foregroundStyle(.red)
                    Spacer()
                    switch ScheduleHelper.getSemesterStatus(for: entry.date, semesterStartDate: data.semesterStartDate) {
                    case .beforeSemester:
                        Text("学期未开始")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    case .afterSemester:
                        Text("学期已结束")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    case .inSemester:
                        if let currentWeek = ScheduleHelper.calculateCurrentWeek(from: data.semesterStartDate, for: entry.date) {
                            Text("第 \(currentWeek) 周")
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                        } else {
                            Text("无法计算当前周")
                                .font(.system(size: 14))
                                .foregroundStyle(.red)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                courseScheduleView(data: data)
            }
        } else {
            Text("请先在App中查询课表")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }

    func courseScheduleView(data: CourseScheduleData) -> some View {
        Group {
            switch ScheduleHelper.getSemesterStatus(for: entry.date, semesterStartDate: data.semesterStartDate) {
            case .beforeSemester:
                VStack {
                    Text("学期未开始")
                    if let daysUntilStart = ScheduleHelper.daysUntilSemesterStart(from: data.semesterStartDate, currentDate: entry.date) {
                        Text("还有 \(daysUntilStart) 天开学")
                            .font(.system(size: 12))
                            .foregroundStyle(.primary)
                            .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            case .afterSemester:
                Text("学期已结束")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            case .inSemester:
                let currentWeek = ScheduleHelper.calculateCurrentWeek(from: data.semesterStartDate, for: entry.date) ?? 1
                let firstVisibleSection = firstVisibleSection(for: entry.date)

                let courseColors = ScheduleHelper.getCourseColors(courses: data.courses)

                VStack {
                    headerView(for: currentWeek, semesterStartDate: data.semesterStartDate)

                    ZStack(alignment: .topLeading) {
                        backgroundGrid(firstVisibleSection: firstVisibleSection)
                        coursesOverlay(for: currentWeek, weeklyCourses: data.weeklyCourses, firstVisibleSection: firstVisibleSection, courseColors: courseColors)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }

    func headerView(for week: Int, semesterStartDate: Date) -> some View {
        let dates = getDatesForWeek(week, semesterStartDate: semesterStartDate)
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "M"
        let monthString = monthFormatter.string(from: dates.first ?? Date())

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"

        return HStack(spacing: colSpacing) {
            VStack {
                Text(monthString)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text("月")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .frame(width: timeColWidth)

            ForEach(Array(zip(DayOfWeek.allCases, dates)), id: \.0) { day, date in
                VStack {
                    Text(dayOfWeekToString(day))
                        .font(.subheadline)
                        .foregroundStyle(isToday(date) ? .primary : .secondary)
                        .fontWeight(isToday(date) ? .bold : .regular)
                    Text(dayFormatter.string(from: date))
                        .font(.subheadline)
                        .foregroundStyle(isToday(date) ? .primary : .secondary)
                        .fontWeight(isToday(date) ? .bold : .regular)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: headerHeight)
    }

    func backgroundGrid(firstVisibleSection: Int) -> some View {
        HStack(spacing: colSpacing) {
            VStack(spacing: rowSpacing) {
                ForEach(firstVisibleSection ..< firstVisibleSection + 4, id: \.self) { section in
                    VStack {
                        Text("\(section)")
                            .font(.caption)
                            .fontWeight(.medium)
                        // sectionTime 数组索引从0开始
                        if section - 1 < sectionTime.count {
                            Text(sectionTime[section - 1].0)
                                .font(.system(size: 10))
                            Text(sectionTime[section - 1].1)
                                .font(.system(size: 10))
                        }
                    }
                    .frame(width: timeColWidth, height: sectionHeight)
                }
            }
            ForEach(DayOfWeek.allCases, id: \.self) { _ in
                VStack(spacing: rowSpacing) {
                    ForEach(1 ... 2, id: \.self) { _ in
                        Rectangle()
                            .fill(Color(.secondarySystemBackground))
                            .frame(height: sectionHeight * 2 + rowSpacing)
                            .cornerRadius(5)
                    }
                }
            }
        }
        .padding(.horizontal, 5)
    }

    // MARK: - 课程浮层视图

    private func coursesOverlay(for week: Int, weeklyCourses: [Int: [CourseDisplayInfo]], firstVisibleSection: Int, courseColors: [String: Color]) -> some View {
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
                        // 过滤出在当前可见范围内的课程
                        if courseInfo.session.endSection >= firstVisibleSection && courseInfo.session.startSection < firstVisibleSection + 4 {
                            CourseCardView(
                                course: courseInfo.course,
                                session: courseInfo.session,
                                color: courseColors[courseInfo.course.courseName] ?? .gray
                            )
                            .frame(width: dayColumnWidth)
                            .frame(height: calculateHeight(for: courseInfo.session, firstVisibleSection: firstVisibleSection))
                            .offset(
                                x: horizontalPadding + calculateXOffset(for: courseInfo.session.dayOfWeek, columnWidth: dayColumnWidth),
                                y: calculateYOffset(for: courseInfo.session, firstVisibleSection: firstVisibleSection)
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - 课程卡片视图

    struct CourseCardView: View {
        let course: Course
        let session: ScheduleSession
        let color: Color

        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(course.courseName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)

                Text("@\(session.classroom ?? "待定")")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(color)
            .cornerRadius(5)
            .clipped() // 确保内容不会溢出圆角
        }
    }

    let sectionTime: [(String, String)] = [
        ("08:00", "08:45"), ("08:55", "09:40"), // 大节 1
        ("10:10", "10:55"), ("11:05", "11:50"), // 大节 2
        ("14:00", "14:45"), ("14:55", "15:40"), // 大节 3
        ("16:10", "16:55"), ("17:05", "17:50"), // 大节 4
        ("19:30", "20:15"), ("20:25", "21:10"), // 大节 5
    ]

    let colSpacing: CGFloat = 4
    let rowSpacing: CGFloat = 4
    let timeColWidth: CGFloat = 35
    let headerHeight: CGFloat = 50
    let sectionHeight: CGFloat = 55
    let weekCount: Int = 20

    // MARK: - 动态计算函数

    /// 根据当前时间决定课表应显示的第一个小节
    func firstVisibleSection(for date: Date) -> Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentTimeInMinutes = hour * 60 + minute

        // 各时间段的结束时间（分钟）
        let endOfMajorSection1 = 9 * 60 + 40 // 09:40
        let endOfMajorSection2 = 11 * 60 + 50 // 11:50
        let endOfMajorSection3 = 15 * 60 + 40 // 15:40

        if currentTimeInMinutes <= endOfMajorSection1 {
            return 1 // 显示 1-4 节
        } else if currentTimeInMinutes <= endOfMajorSection2 {
            return 3 // 显示 3-6 节
        } else if currentTimeInMinutes <= endOfMajorSection3 {
            return 5 // 显示 5-8 节
        } else {
            return 7 // 显示 7-10 节
        }
    }

    // 计算课程卡片的高度，考虑课程是否被截断
    func calculateHeight(for session: ScheduleSession, firstVisibleSection: Int) -> CGFloat {
        let start = max(session.startSection, firstVisibleSection)
        let end = min(session.endSection, firstVisibleSection + 3)
        let sections = CGFloat(end - start + 1)

        guard sections > 0 else { return 0 }
        return sections * sectionHeight + (sections - 1) * rowSpacing
    }

    // 计算课程卡片的 Y 轴偏移
    func calculateYOffset(for session: ScheduleSession, firstVisibleSection: Int) -> CGFloat {
        let start = max(session.startSection, firstVisibleSection)
        // 偏移量是相对于可见区域的起始节次
        let y = CGFloat(start - firstVisibleSection)
        return y * sectionHeight + y * rowSpacing
    }

    // 计算课程卡片的 X 轴偏移
    func calculateXOffset(for day: DayOfWeek, columnWidth: CGFloat) -> CGFloat {
        let x = CGFloat(day.rawValue)
        return timeColWidth + colSpacing + (x * columnWidth) + (x * colSpacing)
    }

    func getDatesForWeek(_ week: Int, semesterStartDate: Date) -> [Date] {
        var dates: [Date] = []
        guard let calendar = Calendar(identifier: .gregorian) as Calendar? else { return [] }

        // 计算该周的周日是哪一天
        let daysToAdd = (week - 1) * 7
        guard let firstDayOfWeek = calendar.date(byAdding: .day, value: daysToAdd, to: semesterStartDate) else { return [] }

        // 从周日开始，生成7天的日期
        for i in 0 ..< 7 {
            if let date = calendar.date(byAdding: .day, value: i, to: firstDayOfWeek) {
                dates.append(date)
            }
        }
        return dates
    }

    func dayOfWeekToString(_ day: DayOfWeek) -> String {
        switch day {
        case .sunday: return "日"
        case .monday: return "一"
        case .tuesday: return "二"
        case .wednesday: return "三"
        case .thursday: return "四"
        case .friday: return "五"
        case .saturday: return "六"
        }
    }

    func isToday(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date, inSameDayAs: entry.date)
    }
}

#Preview(as: .systemLarge) {
    WeeklyCoursesWidget()
} timeline: {
    mockWeeklyCoursesEntry()
}
