//
//  CustomCourseScheduleHelper.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/8/2.
//

import CSUSTKit
import Combine
import Foundation
import GRDB

enum CustomCourseScheduleError: LocalizedError {
    /// 无学校课表数据可导入
    case noSchoolScheduleData
    /// 当前激活的课表不能删除
    case activatedScheduleCannotDelete
    /// 开学日期必须为周日
    case invalidSemesterStartDate
    /// 课表名称不能为空
    case invalidScheduleName

    var errorDescription: String? {
        switch self {
        case .noSchoolScheduleData:
            return "暂无学校课表数据，请先在「我的课表」页面刷新"
        case .activatedScheduleCannotDelete:
            return "此课表为当前选择课表，不能删除，请先切换到其他课表再删除"
        case .invalidSemesterStartDate:
            return "开学日期必须是周日"
        case .invalidScheduleName:
            return "名称不能为空"
        }
    }
}

enum CustomCourseScheduleHelper {
    /// 当前课表 ID，nil 表示默认课表（学校课表）
    static var currentScheduleID: String? {
        MMKVHelper.CourseSchedule.currentScheduleID
    }

    // MARK: - 写操作

    /// 从空白创建课表
    static func insertEmptySchedule(name: String, semesterStartDate: Date) throws {
        guard CourseScheduleUtil.getDayOfWeek(semesterStartDate) == .sunday else {
            throw CustomCourseScheduleError.invalidSemesterStartDate
        }
        let schedule = CustomCourseScheduleGRDB(
            id: UUID().uuidString,
            name: name,
            semesterStartDate: semesterStartDate,
            weekCount: CourseScheduleUtil.weekCount,
            remarks: "",
            createdAt: .now
        )
        try insertSchedule(schedule, courses: [], sessions: [])
        syncActiveCourseSchedule()
    }

    /// 从学校课表导入课表
    static func importSchoolSchedule(name: String) throws {
        guard let schoolCache = MMKVHelper.CourseSchedule.cache else {
            throw CustomCourseScheduleError.noSchoolScheduleData
        }

        let data = schoolCache.value
        let scheduleID = UUID().uuidString
        let schedule = CustomCourseScheduleGRDB(
            id: scheduleID,
            name: name,
            semesterStartDate: data.semesterStartDate,
            weekCount: CourseScheduleUtil.resolveWeekCount(data.weekCount),
            remarks: data.remarks.joined(separator: "\n"),
            createdAt: .now
        )

        var courses: [CustomCourseGRDB] = []
        var sessions: [CustomSessionGRDB] = []
        for course in data.courses {
            let courseID = UUID().uuidString
            courses.append(
                CustomCourseGRDB(
                    id: courseID,
                    scheduleId: scheduleID,
                    courseName: course.courseName,
                    teacher: course.teacher,
                    groupName: course.groupName
                )
            )
            for session in course.sessions {
                sessions.append(
                    CustomSessionGRDB(
                        id: UUID().uuidString,
                        courseId: courseID,
                        dayOfWeek: session.dayOfWeek.rawValue,
                        startSection: session.startSection,
                        endSection: session.endSection,
                        classroom: session.classroom,
                        weeks: JSONIntArray(session.weeks)
                    )
                )
            }
        }

        try insertSchedule(schedule, courses: courses, sessions: sessions)
        syncActiveCourseSchedule()
    }

    /// 删除课表（当前激活的课表不可删除）
    static func deleteSchedule(id scheduleID: String) throws {
        guard scheduleID != currentScheduleID else {
            throw CustomCourseScheduleError.activatedScheduleCannotDelete
        }

        try DatabaseManager.shared.poolThrows.write { db in
            _ = try CustomCourseScheduleGRDB.deleteOne(db, key: scheduleID)
        }
        syncActiveCourseSchedule()
    }

    /// 更新课表信息（名称/开学日期/总周数/备注），返回 trim 后的名称
    @discardableResult
    static func updateSchedule(id scheduleID: String, name: String, semesterStartDate: Date, weekCount: Int, remarks: String) throws -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw CustomCourseScheduleError.invalidScheduleName
        }
        guard CourseScheduleUtil.getDayOfWeek(semesterStartDate) == .sunday else {
            throw CustomCourseScheduleError.invalidSemesterStartDate
        }

        try DatabaseManager.shared.poolThrows.write { db in
            guard var schedule = try CustomCourseScheduleGRDB.fetchOne(db, key: scheduleID) else {
                return
            }
            schedule.name = trimmedName
            schedule.semesterStartDate = semesterStartDate
            schedule.weekCount = weekCount
            schedule.remarks = remarks
            try schedule.update(db)
        }
        syncActiveCourseSchedule()
        return trimmedName
    }

    /// 激活指定课表；传入 nil 切回默认课表
    static func activateSchedule(id scheduleID: String?) {
        guard scheduleID != currentScheduleID else { return }
        MMKVHelper.CourseSchedule.currentScheduleID = scheduleID
        syncActiveCourseSchedule()
    }

    /// 同步当前生效课表到 KV 镜像。
    /// 学校课表缓存等外部写入场景需手动调用此方法。
    static func syncActiveCourseSchedule() {
        MMKVHelper.CourseSchedule.activeCourseSchedule = Cached(
            cachedAt: .now,
            value: currentActiveCourseSchedule()
        )
    }

    // MARK: - 读取

    /// 当前生效课表：
    /// - 默认课表：取 MMKV 缓存的学校课表
    /// - 自定义课表：从 GRDB 读取并转换，名称为课表名
    static func currentActiveCourseSchedule() -> ActiveCourseSchedule {
        guard let scheduleID = currentScheduleID else {
            let data = MMKVHelper.CourseSchedule.cache?.value
            return ActiveCourseSchedule(
                data: data,
                isCustomSchedule: false,
                scheduleName: data?.semester
            )
        }
        guard let pool = DatabaseManager.shared.pool else {
            return ActiveCourseSchedule(data: nil, isCustomSchedule: true, scheduleName: nil)
        }

        do {
            let (schedule, courses, sessions) = try pool.read { db -> (CustomCourseScheduleGRDB?, [CustomCourseGRDB], [CustomSessionGRDB]) in
                let schedule = try CustomCourseScheduleGRDB.fetchOne(db, key: scheduleID)
                guard let schedule else {
                    return (nil, [], [])
                }
                let courses =
                    try CustomCourseGRDB
                    .filter(CustomCourseGRDB.Columns.scheduleId == schedule.id)
                    .fetchAll(db)
                let courseIDs = courses.map(\.id)
                let sessions =
                    try CustomSessionGRDB
                    .filter(courseIDs.contains(CustomSessionGRDB.Columns.courseId))
                    .fetchAll(db)
                return (schedule, courses, sessions)
            }
            guard let schedule else {
                return ActiveCourseSchedule(data: nil, isCustomSchedule: true, scheduleName: nil)
            }

            let sessionsByCourseID = Dictionary(grouping: sessions, by: \.courseId)
            let eduCourses = courses.map { course -> EduHelper.Course in
                let eduSessions = (sessionsByCourseID[course.id] ?? []).compactMap { session -> EduHelper.ScheduleSession? in
                    guard let dayOfWeek = EduHelper.DayOfWeek(rawValue: session.dayOfWeek) else {
                        return nil
                    }
                    return EduHelper.ScheduleSession(
                        weeks: session.weeks.values,
                        startSection: session.startSection,
                        endSection: session.endSection,
                        dayOfWeek: dayOfWeek,
                        classroom: session.classroom
                    )
                }
                return EduHelper.Course(
                    courseName: course.courseName,
                    groupName: course.groupName,
                    teacher: course.teacher,
                    sessions: eduSessions
                )
            }

            return ActiveCourseSchedule(
                data: CourseScheduleData(
                    semester: nil,
                    semesterStartDate: schedule.semesterStartDate,
                    courses: eduCourses,
                    remarks: schedule.remarks
                        .components(separatedBy: "\n")
                        .filter { !$0.isEmpty },
                    weekCount: schedule.weekCount
                ),
                isCustomSchedule: true,
                scheduleName: schedule.name
            )
        } catch {
            return ActiveCourseSchedule(data: nil, isCustomSchedule: true, scheduleName: nil)
        }
    }

    // MARK: - Private

    private static func insertSchedule(_ schedule: CustomCourseScheduleGRDB, courses: [CustomCourseGRDB], sessions: [CustomSessionGRDB]) throws {
        try DatabaseManager.shared.poolThrows.write { db in
            var schedule = schedule
            try schedule.insert(db)
            for course in courses {
                var course = course
                try course.insert(db)
            }
            for session in sessions {
                var session = session
                try session.insert(db)
            }
        }
    }
}
