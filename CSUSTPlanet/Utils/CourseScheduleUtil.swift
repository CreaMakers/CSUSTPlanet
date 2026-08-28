//
//  CourseScheduleUtil.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/17.
//

import CSUSTKit
import Foundation

enum SemesterStatus {
    case beforeSemester
    case inSemester
    case afterSemester
}

enum TodayCourseState {
    case noScheduledCourses
    case finishedAllCourses
    case unfinishedCourses(courses: [(course: CourseDisplayInfo, isCurrent: Bool)])
}

enum TodayCourseFallbackReason {
    case noScheduledCourses
    case finishedAllCourses

    var message: String {
        switch self {
        case .noScheduledCourses:
            return CourseScheduleUtil.noScheduledCoursesTodayText
        case .finishedAllCourses:
            return CourseScheduleUtil.finishedCoursesTodayText
        }
    }
}

struct TomorrowCoursePreview {
    let date: Date
    let courses: [CourseDisplayInfo]
}

enum DailyCourseDisplayState {
    case today(courses: [(course: CourseDisplayInfo, isCurrent: Bool)])
    case tomorrowPreview(reason: TodayCourseFallbackReason, preview: TomorrowCoursePreview?)
}

enum CourseScheduleUtil {

    // MARK: - Properties

    /// 默认学期总周数，学校课表固定为 20 周，也是自定义课表周数为 nil 时的兜底值
    static let weekCount: Int = 20

    /// 解析课表总周数，传入 nil 时使用默认值
    static func resolveWeekCount(_ weekCount: Int?) -> Int {
        weekCount ?? Self.weekCount
    }

    /// 课程均以长沙当地时间为准
    static let courseTimeZone = TimeZone(identifier: "Asia/Shanghai")!

    /// 课程节次时间表
    static let sectionTimeString: [(String, String)] = [
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

    /// 月份格式化器 用于显示月份 `M`
    static var monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M"
        formatter.timeZone = courseTimeZone
        return formatter
    }()

    /// 日期格式化器 用于显示日 `d`
    static var dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        formatter.timeZone = courseTimeZone
        return formatter
    }()

    /// 日期格式化器 用于显示日期 `yyyy-MM-dd`
    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = courseTimeZone
        return formatter
    }()

    /// 开学前多少天内显示具体倒计时，超过此天数则显示鼓励语
    static let semesterStartThreshold: Int = 7

    /// 假期鼓励语
    static let holidayMessages: [String] = [
        "好好享受假期吧！",
        "假期余额充足。",
        "今天只管玩！",
        "享受当下的闲暇时光吧！",
        "去看看外面的世界。",
        "休息是为了走更远的路。",
        "祝你今天玩得开心！",
        "假期就该轻松点。",
        "还没开学，再睡会？",
        "不赶时间，慢慢来。",
        "今天也是元气满满的一天！",
        "放下压力，轻松一下。",
        "生活不只有课表，还有远方。",
        "记得给心情放个假。",
        "难得清闲，读一本好书。",
        "保持热爱，奔赴山海。",
        "好心情是最好的良药。",
        "偷得浮生半日闲。",
        "愿你今天有个好梦。",
    ]

    /// 课表相关统一文案
    static let courseScheduleTitle: String = "我的课表"
    static let emptyCourseScheduleText: String = "暂无课表数据"
    static let semesterNotStartedText: String = "学期未开始"
    static let semesterEndedText: String = "本学期已结束"
    static let noScheduledCoursesTodayText: String = "今天没有课程，好好休息吧"
    static let finishedCoursesTodayText: String = "今天的课程已经上完啦"
    static let tomorrowCoursesTitleText: String = "以下为明日课程"
    static let noScheduledCoursesTomorrowText: String = "明天也没课哦"

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = courseTimeZone
        return calendar
    }()

    // MARK: - Methods

    /// 将教务系统按设备时区解析的日期规范化为上海时区下的同一自然日
    static func normalizeSemesterStartDate(_ date: Date, sourceCalendar: Calendar = .current) -> Date {
        let components = sourceCalendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: components)!
    }

    /// 获取学期覆盖的半开时间区间 `[开学日, 开学日 + weekCount周)`
    /// - Parameters:
    ///   - semesterStartDate: 学期开始日期
    ///   - weekCount: 课表总周数，nil 时使用默认值 20
    static func getSemesterDateRange(semesterStartDate: Date, weekCount: Int? = nil) -> (startDate: Date, endDate: Date) {
        let startDate = calendar.startOfDay(for: semesterStartDate)
        let endDate = calendar.date(byAdding: .weekOfYear, value: resolveWeekCount(weekCount), to: startDate)!
        return (startDate, endDate)
    }

    /// 计算周到课程列表的字典 用于显示整个课表
    /// - Returns: 周到课程列表的字典
    static func getWeeklyCourses(_ courses: [EduHelper.Course]) -> [Int: [CourseDisplayInfo]] {
        var weeklyCourses: [Int: [CourseDisplayInfo]] = [:]
        for course in courses {
            for session in course.sessions {
                let displayInfo = CourseDisplayInfo(course: course, session: session)
                for week in session.weeks {
                    weeklyCourses[week, default: []].append(displayInfo)
                }
            }
        }
        return weeklyCourses
    }

    /// 通过学期开始日期和当前时间来计算当前周
    /// - Parameters:
    ///   - semesterStartDate: 学期开始日期
    ///   - now: 当前时间
    ///   - weekCount: 课表总周数，nil 时使用默认值
    /// - Returns: 当前周数，若当前日期在学期开始前或学期结束后则返回nil
    static func getCurrentWeek(semesterStartDate: Date, now: Date, weekCount: Int? = nil) -> Int? {
        let startDate = calendar.startOfDay(for: semesterStartDate)
        let todayDate = calendar.startOfDay(for: now)

        // 计算两个日期之间相差的天数
        let components = calendar.dateComponents([.day], from: startDate, to: todayDate)
        guard let days = components.day else { return 1 }

        if days < 0 { return nil }

        // 天数除以7，结果加1就是周数
        let weekNumber = Int(floor(Double(days) / 7.0)) + 1

        if weekNumber < 1 || weekNumber > resolveWeekCount(weekCount) {
            return nil
        }

        return weekNumber
    }

    /// 获取指定周的所有日期（周日、周一、...、周六）
    /// - Parameters:
    ///   - semesterStartDate: 学期开始日期
    ///   - week: 第几周
    /// - Returns: 该周的所有日期数组
    static func getDatesForWeek(semesterStartDate: Date, week: Int) -> [Date] {
        // 计算该周的周日是哪一天
        let daysToAdd = (week - 1) * 7
        let firstDayOfWeek = calendar.date(byAdding: .day, value: daysToAdd, to: semesterStartDate)!

        // 从周日开始，生成7天的日期
        return (0..<7).map { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: firstDayOfWeek)!
        }
    }

    /// 根据给定的学期开始时间、周次和课程小节信息，计算课程具体的开始和结束日期时间
    /// - Parameters:
    ///   - session: 课程小节信息
    ///   - week: 第几周
    ///   - semesterStartDate: 学期开始日期
    /// - Returns: 课程的开始日期时间和结束日期时间
    static func getCourseEventDates(
        session: EduHelper.ScheduleSession,
        week: Int,
        semesterStartDate: Date
    ) -> (startDate: Date, endDate: Date) {
        let datesOfWeek = getDatesForWeek(semesterStartDate: semesterStartDate, week: week)

        // 通过这一周的每一天的时间和这一节课在周几，定位到当前课程课时的具体日期
        let targetDate = datesOfWeek[session.dayOfWeek.rawValue]

        // 找到这节课在这一天的具体时间
        let startSectionIndex = session.startSection - 1
        let endSectionIndex = session.endSection - 1
        let startTimeString = sectionTimeString[startSectionIndex].0
        let endTimeString = sectionTimeString[endSectionIndex].1
        let startComponents = startTimeString.split(separator: ":").map { Int($0)! }
        let endComponents = endTimeString.split(separator: ":").map { Int($0)! }

        let eventStartDate = calendar.date(
            bySettingHour: startComponents[0],
            minute: startComponents[1],
            second: 0,
            of: targetDate
        )!
        let eventEndDate = calendar.date(
            bySettingHour: endComponents[0],
            minute: endComponents[1],
            second: 0,
            of: targetDate
        )!

        return (startDate: eventStartDate, endDate: eventEndDate)
    }

    /// 判断指定日期是否为今天
    /// - Parameter date: 指定日期
    /// - Returns: 是否为今天
    static func isToday(_ date: Date) -> Bool {
        return calendar.isDateInToday(date)
    }

    /// 获取当前学期状态（开学前、学期中、学期后）
    /// - Parameters:
    ///   - semesterStartDate: 学期开始日期
    ///   - date: 目标日期
    ///   - weekCount: 课表总周数，nil 时使用默认值
    /// - Returns: 当前学期状态
    static func getSemesterStatus(semesterStartDate: Date, date: Date, weekCount: Int? = nil) -> SemesterStatus {
        let targetDate = calendar.startOfDay(for: date)
        let startDate = calendar.startOfDay(for: semesterStartDate)

        guard let endDate = calendar.date(byAdding: .weekOfYear, value: resolveWeekCount(weekCount), to: startDate) else {
            return .afterSemester
        }

        if targetDate < startDate {
            return .beforeSemester
        } else if targetDate >= startDate && targetDate < endDate {
            return .inSemester
        } else {
            return .afterSemester
        }
    }

    /// 获取日期对应的星期
    /// - Parameter date: 目标日期
    /// - Returns: 星期
    static func getDayOfWeek(_ date: Date) -> EduHelper.DayOfWeek {
        let weekday = calendar.component(.weekday, from: date)

        switch weekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .sunday
        }
    }

    /// 计算当前距离开学还有多少天
    /// - Parameters:
    ///   - semesterStartDate: 学期开始日期
    ///   - currentDate: 当前日期
    /// - Returns: 距离开学的天数（如果开学日期在未来），否则返回nil
    static func getDaysUntilSemesterStart(semesterStartDate: Date, currentDate: Date) -> Int? {
        let startDate = calendar.startOfDay(for: semesterStartDate)
        let today = calendar.startOfDay(for: currentDate)
        let components = calendar.dateComponents([.day], from: today, to: startDate)
        guard let days = components.day else { return nil }
        return days > 0 ? days : nil
    }

    static func getSemesterCountdownText(days: Int) -> String {
        return "距离开学还有 \(days) 天"
    }

    static func getCoursesForDate(
        semesterStartDate: Date,
        targetDate: Date,
        courses: [EduHelper.Course],
        weekCount: Int? = nil
    ) -> [CourseDisplayInfo] {
        return getCoursesForTargetDate(
            semesterStartDate: semesterStartDate,
            targetDate: targetDate,
            courses: courses,
            weekCount: weekCount
        )
    }

    private static func getCoursesForTargetDate(
        semesterStartDate: Date,
        targetDate: Date,
        courses: [EduHelper.Course],
        weekCount: Int? = nil
    ) -> [CourseDisplayInfo] {
        guard let currentWeek = getCurrentWeek(semesterStartDate: semesterStartDate, now: targetDate, weekCount: weekCount) else {
            return []
        }

        let currentDayOfWeek = getDayOfWeek(targetDate)
        return courses.flatMap { course in
            course.sessions.compactMap { session -> CourseDisplayInfo? in
                guard session.weeks.contains(currentWeek), session.dayOfWeek == currentDayOfWeek else {
                    return nil
                }
                return CourseDisplayInfo(course: course, session: session)
            }
        }
        .sorted { $0.session.startSection < $1.session.startSection }
    }

    private static func getUnfinishedCoursesForTargetDate(
        _ dailyCourses: [CourseDisplayInfo],
        now: Date
    ) -> [(course: CourseDisplayInfo, isCurrent: Bool)] {
        return dailyCourses.compactMap { courseInfo -> (course: CourseDisplayInfo, isCurrent: Bool)? in
            let startSectionIndex = courseInfo.session.startSection - 1
            let endSectionIndex = courseInfo.session.endSection - 1
            guard startSectionIndex >= 0, startSectionIndex < sectionTimeString.count,
                endSectionIndex >= 0, endSectionIndex < sectionTimeString.count
            else {
                return nil
            }

            let startTimeString = sectionTimeString[startSectionIndex].0
            let endTimeString = sectionTimeString[endSectionIndex].1
            let startComponents = startTimeString.split(separator: ":").compactMap { Int($0) }
            let endComponents = endTimeString.split(separator: ":").compactMap { Int($0) }

            guard startComponents.count == 2, endComponents.count == 2,
                let courseStartDate = calendar.date(bySettingHour: startComponents[0], minute: startComponents[1], second: 0, of: now),
                let courseEndDate = calendar.date(bySettingHour: endComponents[0], minute: endComponents[1], second: 0, of: now)
            else {
                return nil
            }

            guard now < courseEndDate else {
                return nil
            }

            let isCurrent = now >= courseStartDate
            return (course: courseInfo, isCurrent: isCurrent)
        }
    }

    static func getTomorrowCoursePreview(
        semesterStartDate: Date,
        now: Date,
        courses: [EduHelper.Course],
        weekCount: Int? = nil
    ) -> TomorrowCoursePreview? {
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else {
            return nil
        }

        let tomorrowCourses = getCoursesForDate(
            semesterStartDate: semesterStartDate,
            targetDate: tomorrow,
            courses: courses,
            weekCount: weekCount
        )
        guard !tomorrowCourses.isEmpty else {
            return nil
        }

        return TomorrowCoursePreview(date: tomorrow, courses: tomorrowCourses)
    }

    static func getTodayCourseState(
        semesterStartDate: Date,
        now: Date,
        courses: [EduHelper.Course],
        weekCount: Int? = nil
    ) -> TodayCourseState {
        let dailyCourses = getCoursesForTargetDate(
            semesterStartDate: semesterStartDate,
            targetDate: now,
            courses: courses,
            weekCount: weekCount
        )

        guard !dailyCourses.isEmpty else {
            return .noScheduledCourses
        }

        let unfinishedCourses = getUnfinishedCoursesForTargetDate(dailyCourses, now: now)
        guard !unfinishedCourses.isEmpty else {
            return .finishedAllCourses
        }

        return .unfinishedCourses(courses: unfinishedCourses)
    }

    static func getDailyCourseDisplayState(
        semesterStartDate: Date,
        now: Date,
        courses: [EduHelper.Course],
        weekCount: Int? = nil
    ) -> DailyCourseDisplayState {
        switch getTodayCourseState(semesterStartDate: semesterStartDate, now: now, courses: courses, weekCount: weekCount) {
        case .unfinishedCourses(let courses):
            return .today(courses: courses)
        case .noScheduledCourses:
            return .tomorrowPreview(
                reason: .noScheduledCourses,
                preview: getTomorrowCoursePreview(semesterStartDate: semesterStartDate, now: now, courses: courses, weekCount: weekCount)
            )
        case .finishedAllCourses:
            return .tomorrowPreview(
                reason: .finishedAllCourses,
                preview: getTomorrowCoursePreview(semesterStartDate: semesterStartDate, now: now, courses: courses, weekCount: weekCount)
            )
        }
    }

    /// 获取当天未结束的课程列表
    /// - Parameters:
    ///   - semesterStartDate: 学期开始日期
    ///   - now: 当前时间
    ///   - courses: 课程列表
    ///   - weekCount: 课表总周数，nil 时使用默认值
    /// - Returns: 一个包含未结束课程信息和是否为当前课程的元组数组
    static func getUnfinishedCourses(semesterStartDate: Date, now: Date, courses: [EduHelper.Course], weekCount: Int? = nil) -> [(course: CourseDisplayInfo, isCurrent: Bool)] {
        let dailyCourses = getCoursesForTargetDate(
            semesterStartDate: semesterStartDate,
            targetDate: now,
            courses: courses,
            weekCount: weekCount
        )
        return getUnfinishedCoursesForTargetDate(dailyCourses, now: now)
    }

    /// 获取用于“课程状态”实时活动功能的课程信息
    ///
    /// 查找逻辑按以下优先级进行：
    /// 1. 返回当前正在进行的课程。
    /// 2. 如果没有正在进行的课程，则返回20分钟内即将开始的课程。
    /// 3. 如果也没有即将开始的课程，则返回5分钟内刚刚结束的课程，以供实时活动显示结束状态。
    ///
    /// - Parameters:
    ///   - semesterStartDate: 学期开始日期
    ///   - now: 当前时间
    ///   - courses: 课程列表
    ///   - weekCount: 课表总周数，nil 时使用默认值
    /// - Returns: 符合要求的、最相关的课程信息，若无则返回nil
    static func getRelevantCourseForStatus(semesterStartDate: Date, now: Date, courses: [EduHelper.Course], weekCount: Int? = nil) -> CourseDisplayInfo? {
        guard let currentWeek = getCurrentWeek(semesterStartDate: semesterStartDate, now: now, weekCount: weekCount) else {
            return nil
        }

        let currentDayOfWeek = getDayOfWeek(now)
        let todaysCourses = courses.flatMap { course -> [CourseDisplayInfo] in
            course.sessions.compactMap { session -> CourseDisplayInfo? in
                guard session.weeks.contains(currentWeek), session.dayOfWeek == currentDayOfWeek else {
                    return nil
                }
                return CourseDisplayInfo(course: course, session: session)
            }
        }.sorted { $0.session.startSection < $1.session.startSection }

        guard !todaysCourses.isEmpty else {
            return nil
        }

        var closestUpcomingCourse: (info: CourseDisplayInfo, interval: TimeInterval)?
        var mostRecentlyFinishedCourse: (info: CourseDisplayInfo, interval: TimeInterval)?

        for courseInfo in todaysCourses {
            let startSectionIndex = courseInfo.session.startSection - 1
            let endSectionIndex = courseInfo.session.endSection - 1

            guard startSectionIndex >= 0, startSectionIndex < sectionTimeString.count,
                endSectionIndex >= 0, endSectionIndex < sectionTimeString.count
            else {
                continue
            }

            let startTimeString = sectionTimeString[startSectionIndex].0
            let endTimeString = sectionTimeString[endSectionIndex].1
            let startComponents = startTimeString.split(separator: ":").compactMap { Int($0) }
            let endComponents = endTimeString.split(separator: ":").compactMap { Int($0) }

            guard startComponents.count == 2, endComponents.count == 2,
                let courseStartDate = calendar.date(bySettingHour: startComponents[0], minute: startComponents[1], second: 0, of: now),
                let courseEndDate = calendar.date(bySettingHour: endComponents[0], minute: endComponents[1], second: 0, of: now)
            else {
                continue
            }

            if now >= courseStartDate && now < courseEndDate {
                return courseInfo
            }

            if now < courseStartDate {
                let interval = courseStartDate.timeIntervalSince(now)
                if closestUpcomingCourse == nil || interval < closestUpcomingCourse!.interval {
                    closestUpcomingCourse = (info: courseInfo, interval: interval)
                }
            }

            if now >= courseEndDate {
                let interval = now.timeIntervalSince(courseEndDate)
                if mostRecentlyFinishedCourse == nil || interval < mostRecentlyFinishedCourse!.interval {
                    mostRecentlyFinishedCourse = (info: courseInfo, interval: interval)
                }
            }
        }
        if let upcoming = closestUpcomingCourse, upcoming.interval <= 1200 {
            return upcoming.info
        }

        if let finished = mostRecentlyFinishedCourse, finished.interval <= 300 {
            return finished.info
        }

        return nil
    }

    /// 根据日期获取一条随机假期文案
    /// - Parameter date: 基准日期，用于固定同一天的文案（或使用随机）
    /// - Returns: 文案字符串
    static func getHolidayMessage(for date: Date) -> String {
        // 使用日期作为种子，保证同一天看到的文案是一致的，避免 Widget 刷新导致文案乱跳
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 0
        let index = dayOfYear % holidayMessages.count
        return holidayMessages[index]
    }
}

// MARK: - DayOfWeek Extension

extension EduHelper.DayOfWeek {
    /// 将周几枚举转换为对应的中文字符串
    var stringValue: String {
        switch self {
        case .monday: return "一"
        case .tuesday: return "二"
        case .wednesday: return "三"
        case .thursday: return "四"
        case .friday: return "五"
        case .saturday: return "六"
        case .sunday: return "日"
        }
    }
}
