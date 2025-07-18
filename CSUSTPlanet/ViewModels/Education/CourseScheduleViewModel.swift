//
//  CourseScheduleViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/18.
//

import CSUSTKit
import Foundation
import SwiftUI

struct Course: Identifiable {
    let id = UUID()
    let courseName: String
    let groupName: String?
    let teacher: String
    let sessions: [ScheduleSession]
}

struct ScheduleSession: Identifiable {
    let id = UUID()
    let weeks: [Int]
    let startSection: Int
    let endSection: Int
    let dayOfWeek: DayOfWeek
    let classroom: String?
}

@MainActor
class CourseScheduleViewModel: ObservableObject {
    // TabView显示的第几周
    @Published var currentWeek: Int = 1
    @Published var courses: [Course] = [Course(courseName: "程序设计、算法与数据结构（二）", groupName: nil, teacher: "邓锬讲师", sessions: [ScheduleSession(weeks: [1, 2, 3, 4, 5, 6, 7, 8], startSection: 1, endSection: 2, dayOfWeek: DayOfWeek.wednesday, classroom: Optional("金1A-408")), ScheduleSession(weeks: [1, 2, 3, 4, 5, 6, 7, 8], startSection: 3, endSection: 4, dayOfWeek: DayOfWeek.monday, classroom: Optional("金1A-408")), ScheduleSession(weeks: [1, 2, 3, 4, 5, 6, 7, 8], startSection: 7, endSection: 8, dayOfWeek: DayOfWeek.friday, classroom: Optional("金1A-408"))]), Course(courseName: "体育(二)", groupName: Optional("(24计通校园马拉松男06)"), teacher: "李龙教授", sessions: [ScheduleSession(weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15], startSection: 3, endSection: 4, dayOfWeek: DayOfWeek.thursday, classroom: Optional("金西田径场5"))]), Course(courseName: "高等数学A（二）", groupName: nil, teacher: "刘演军讲师", sessions: [ScheduleSession(weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16], startSection: 1, endSection: 2, dayOfWeek: DayOfWeek.monday, classroom: Optional("金6-307")), ScheduleSession(weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16], startSection: 1, endSection: 2, dayOfWeek: DayOfWeek.friday, classroom: Optional("金6-307")), ScheduleSession(weeks: [2, 4, 6, 8, 10, 12, 14, 16], startSection: 3, endSection: 4, dayOfWeek: DayOfWeek.tuesday, classroom: Optional("金6-307"))]), Course(courseName: "通用工程英语听说", groupName: nil, teacher: "高海英讲师", sessions: [ScheduleSession(weeks: [1, 3, 5, 7, 9, 11, 13], startSection: 3, endSection: 4, dayOfWeek: DayOfWeek.tuesday, classroom: Optional("金6-403")), ScheduleSession(weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13], startSection: 3, endSection: 4, dayOfWeek: DayOfWeek.friday, classroom: Optional("金6-403"))]), Course(courseName: "大学物理B（上）", groupName: nil, teacher: "李秀凤副教授", sessions: [ScheduleSession(weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16], startSection: 5, endSection: 6, dayOfWeek: DayOfWeek.thursday, classroom: Optional("金6-309"))]), Course(courseName: "程序设计、算法与数据结构（二）实验", groupName: nil, teacher: "邓锬讲师", sessions: [ScheduleSession(weeks: [9, 10, 11, 12, 13], startSection: 1, endSection: 2, dayOfWeek: DayOfWeek.wednesday, classroom: Optional("金1A-408")), ScheduleSession(weeks: [9, 10, 11, 12, 13], startSection: 3, endSection: 4, dayOfWeek: DayOfWeek.monday, classroom: Optional("金1A-408")), ScheduleSession(weeks: [9, 10, 11, 12, 13], startSection: 7, endSection: 8, dayOfWeek: DayOfWeek.friday, classroom: Optional("金1A-408"))]), Course(courseName: "军事理论", groupName: nil, teacher: "军事教研室", sessions: [ScheduleSession(weeks: [5, 12], startSection: 5, endSection: 8, dayOfWeek: DayOfWeek.tuesday, classroom: Optional("金6-209"))]), Course(courseName: "思想道德与法治", groupName: nil, teacher: "严苏海讲师", sessions: [ScheduleSession(weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16], startSection: 3, endSection: 4, dayOfWeek: DayOfWeek.wednesday, classroom: Optional("金6-202"))]), Course(courseName: "程序设计、算法与数据结构（一）实验", groupName: nil, teacher: "李平(08)教授", sessions: [ScheduleSession(weeks: [4, 5, 6, 8, 9, 12], startSection: 5, endSection: 8, dayOfWeek: DayOfWeek.sunday, classroom: Optional("金1A-212")), ScheduleSession(weeks: [3, 4, 5, 7, 8, 9], startSection: 5, endSection: 8, dayOfWeek: DayOfWeek.saturday, classroom: Optional("金1A-212"))]), Course(courseName: "程序设计、算法与数据结构（一）", groupName: nil, teacher: "李平(08)教授", sessions: [ScheduleSession(weeks: [4, 5, 6, 8, 9, 12], startSection: 1, endSection: 4, dayOfWeek: DayOfWeek.sunday, classroom: Optional("金1A-212")), ScheduleSession(weeks: [3, 4, 5, 7, 8, 9], startSection: 1, endSection: 4, dayOfWeek: DayOfWeek.saturday, classroom: Optional("金1A-212"))]), Course(courseName: "信息类专业导论", groupName: nil, teacher: "李平(08)教授", sessions: [ScheduleSession(weeks: [13, 14], startSection: 1, endSection: 4, dayOfWeek: DayOfWeek.sunday, classroom: Optional("金1A-212")), ScheduleSession(weeks: [13, 14], startSection: 1, endSection: 4, dayOfWeek: DayOfWeek.saturday, classroom: Optional("金1A-212"))])]

    // 开学日期
    var semesterStartDate: Date? = nil
    // 当日日期
    let today: Date = .now
    // 当前日期在第几周
    var realCurrentWeek: Int = 1

    let colSpacing: CGFloat = 4 // 列间距
    let rowSpacing: CGFloat = 4 // 行间距
    let timeColWidth: CGFloat = 35 // 左侧时间列宽度
    let headerHeight: CGFloat = 50 // 顶部日期行的高度
    let sectionHeight: CGFloat = 70 // 单个课程格子的高度
    let weekCount: Int = 30 // 学期总周数

    let sectionTime: [(String, String)] = [
        ("08:00", "08:45"),
        ("08:55", "09:40"),
        ("10:10", "10:55"),
        ("11:05", "11:50"),
        ("14:00", "14:45"),
        ("14:55", "15:40"),
        ("16:10", "16:55"),
        ("17:05", "17:50"),
        ("19:30", "20:15"),
        ("20:25", "21:10"),
    ]

    var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    init() {
        self.semesterStartDate = dateFormatter.date(from: "2025-02-23")!
        self.realCurrentWeek = calculateCurrentWeek(from: semesterStartDate!, for: today)
        self.currentWeek = realCurrentWeek
    }

    func goToCurrentWeek() {
        withAnimation {
            self.currentWeek = realCurrentWeek
        }
    }

    // 计算指定日期属于第几周
    func calculateCurrentWeek(from start: Date, for date: Date) -> Int {
        // Calendar.current.startOfDay(for:) 确保我们只比较日期，忽略时间
        let startDate = Calendar.current.startOfDay(for: start)
        let todayDate = Calendar.current.startOfDay(for: date)

        // 计算两个日期之间相差的天数
        let components = Calendar.current.dateComponents([.day], from: startDate, to: todayDate)
        guard let days = components.day else { return 1 }

        // 如果天数是负数（即今天在开学日期之前），则为第1周
        if days < 0 { return 1 }

        // 天数除以7，结果加1就是周数
        let weekNumber = Int(floor(Double(days) / 7.0)) + 1
        if weekNumber > weekCount {
            return weekCount
        }
        return weekNumber
    }

    // 获取指定教学周的所有日期
    func getDatesForWeek(_ week: Int) -> [Date] {
        var dates: [Date] = []
        guard let calendar = Calendar(identifier: .gregorian) as Calendar? else { return [] }

        // 计算该周的周日是哪一天
        let daysToAdd = (week - 1) * 7
        guard let firstDayOfWeek = calendar.date(byAdding: .day, value: daysToAdd, to: semesterStartDate!) else { return [] }

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
        case .monday: return "一"
        case .tuesday: return "二"
        case .wednesday: return "三"
        case .thursday: return "四"
        case .friday: return "五"
        case .saturday: return "六"
        case .sunday: return "日"
        }
    }

    // 计算课程卡片的高度
    func calculateHeight(for session: ScheduleSession) -> CGFloat {
        let sections = CGFloat(session.endSection - session.startSection + 1)
        return sections * sectionHeight + (sections - 1) * rowSpacing
    }

    // 计算课程卡片的 Y 轴偏移
    func calculateYOffset(for session: ScheduleSession) -> CGFloat {
        let y = CGFloat(session.startSection - 1)
        return y * sectionHeight + y * rowSpacing
    }

    // 计算课程卡片的 X 轴偏移
    func calculateXOffset(for day: DayOfWeek, columnWidth: CGFloat) -> CGFloat {
        let x = CGFloat(day.rawValue)
        return timeColWidth + colSpacing + (x * columnWidth) + (x * colSpacing)
    }
}
