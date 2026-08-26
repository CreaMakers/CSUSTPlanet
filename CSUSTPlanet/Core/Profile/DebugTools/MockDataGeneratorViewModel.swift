//
//  MockDataGeneratorViewModel.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/28.
//

#if DEBUG
import CSUSTKit
import Foundation
import GRDB
import Observation

@MainActor
@Observable
final class MockDataGeneratorViewModel {
    var todoAssignmentsCacheDescription = ""
    var examSchedulesCacheDescription = ""
    var courseScheduleCacheDescription = ""
    var electricityCacheDescription = ""
    var errorToast: ToastState = .errorTitle

    func onAppear() {
        refreshTodoAssignmentsCacheDescription()
        refreshExamSchedulesCacheDescription()
        refreshCourseScheduleCacheDescription()
        refreshElectricityCacheDescription()
    }

    func clearTodoAssignmentsCache() {
        MMKVHelper.TodoAssignments.cache = nil
        WidgetTimelineRefreshHelper.reloadTodoAssignments()
        refreshTodoAssignmentsCacheDescription()
    }

    func setEmptyTodoAssignmentsCache() {
        MMKVHelper.TodoAssignments.cache = Cached(cachedAt: .now, value: [])
        WidgetTimelineRefreshHelper.reloadTodoAssignments()
        refreshTodoAssignmentsCacheDescription()
    }

    func generateMockTodoAssignments() {
        MMKVHelper.TodoAssignments.cache = Cached(
            cachedAt: .now,
            value: MockTodoAssignmentsFactory.makeTwoAssignmentsData()
        )
        WidgetTimelineRefreshHelper.reloadTodoAssignments()
        refreshTodoAssignmentsCacheDescription()
    }

    func clearExamSchedulesCache() {
        MMKVHelper.ExamSchedule.cache = nil
        refreshExamSchedulesCacheDescription()
    }

    func setEmptyExamSchedulesCache() {
        MMKVHelper.ExamSchedule.cache = Cached(cachedAt: .now, value: [])
        refreshExamSchedulesCacheDescription()
    }

    func generateMockExamSchedules() {
        MMKVHelper.ExamSchedule.cache = Cached(
            cachedAt: .now,
            value: MockExamSchedulesFactory.makeFiveExamsData()
        )
        refreshExamSchedulesCacheDescription()
    }

    func clearCourseScheduleCache() {
        MMKVHelper.CourseSchedule.cache = nil
        MMKVHelper.CourseSchedule.currentScheduleID = nil
        CustomCourseScheduleHelper.syncActiveCourseSchedule()
        refreshCourseScheduleCacheDescription()
    }

    func setEmptyCourseScheduleCache() {
        MMKVHelper.CourseSchedule.cache = Cached(
            cachedAt: .now,
            value: MockCourseScheduleFactory.makeEmptyCourseScheduleData()
        )
        MMKVHelper.CourseSchedule.currentScheduleID = nil
        CustomCourseScheduleHelper.syncActiveCourseSchedule()
        refreshCourseScheduleCacheDescription()
    }

    func generateTodayFilledCourseSchedule() {
        MMKVHelper.CourseSchedule.cache = Cached(
            cachedAt: .now,
            value: MockCourseScheduleFactory.makeTodayFilledCourseScheduleData()
        )
        MMKVHelper.CourseSchedule.currentScheduleID = nil
        CustomCourseScheduleHelper.syncActiveCourseSchedule()
        refreshCourseScheduleCacheDescription()
    }

    func generateTwoVisibleCourseSchedule() {
        do {
            let data = try MockCourseScheduleFactory.makeTwoVisibleCourseScheduleData()
            MMKVHelper.CourseSchedule.cache = Cached(cachedAt: .now, value: data)
            MMKVHelper.CourseSchedule.currentScheduleID = nil
            CustomCourseScheduleHelper.syncActiveCourseSchedule()
            refreshCourseScheduleCacheDescription()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func generateConflictedCourseSchedule() {
        MMKVHelper.CourseSchedule.cache = Cached(
            cachedAt: .now,
            value: MockCourseScheduleFactory.makeConflictedCourseScheduleData()
        )
        MMKVHelper.CourseSchedule.currentScheduleID = nil
        CustomCourseScheduleHelper.syncActiveCourseSchedule()
        refreshCourseScheduleCacheDescription()
    }

    func generateMockElectricity() {
        guard let pool = DatabaseManager.shared.pool else {
            errorToast.show(message: DatabaseManagerError.databaseUnavailable.localizedDescription)
            return
        }

        do {
            try pool.write { db in
                try MockElectricityFactory.replaceMockDormElectricity(in: db)
            }
            WidgetTimelineRefreshHelper.reloadDormElectricity()
            refreshElectricityCacheDescription()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func refreshTodoAssignmentsCacheDescription() {
        guard let cache = MMKVHelper.TodoAssignments.cache else {
            todoAssignmentsCacheDescription = "当前状态：nil"
            return
        }

        let assignmentCount = cache.value.reduce(into: 0) { partialResult, item in
            partialResult += item.assignments.count
        }

        todoAssignmentsCacheDescription = "当前状态：\(cache.value.count) 门课程，\(assignmentCount) 个作业，缓存时间 \(cache.cachedAt.formatted(date: .abbreviated, time: .standard))"
    }

    private func refreshExamSchedulesCacheDescription() {
        guard let cache = MMKVHelper.ExamSchedule.cache else {
            examSchedulesCacheDescription = "当前状态：nil"
            return
        }

        examSchedulesCacheDescription = "当前状态：\(cache.value.count) 场考试，缓存时间 \(cache.cachedAt.formatted(date: .abbreviated, time: .standard))"
    }

    private func refreshCourseScheduleCacheDescription() {
        guard let cache = MMKVHelper.CourseSchedule.cache else {
            courseScheduleCacheDescription = "当前状态：nil"
            return
        }

        let courseCount = cache.value.courses.count
        let sessionCount = cache.value.courses.reduce(into: 0) { partialResult, course in
            partialResult += course.sessions.count
        }
        let todayCoursesCount = CourseScheduleUtil.getUnfinishedCourses(
            semesterStartDate: cache.value.semesterStartDate,
            now: .now,
            courses: cache.value.courses
        ).count

        courseScheduleCacheDescription = "当前状态：\(cache.value.semester ?? "默认学期")，\(courseCount) 门课程，\(sessionCount) 个上课安排，今日可见 \(todayCoursesCount) 门，缓存时间 \(cache.cachedAt.formatted(date: .abbreviated, time: .standard))"
    }

    private func refreshElectricityCacheDescription() {
        guard let pool = DatabaseManager.shared.pool else {
            electricityCacheDescription = "当前状态：数据库不可用"
            return
        }

        do {
            let state = try pool.read { db -> (DormGRDB?, Int) in
                let dorm =
                    try DormGRDB
                    .filter(DormGRDB.Columns.campusName == MockElectricityFactory.campusName)
                    .filter(DormGRDB.Columns.buildingName == MockElectricityFactory.buildingName)
                    .filter(DormGRDB.Columns.room == MockElectricityFactory.room)
                    .fetchOne(db)

                let recordCount: Int
                if let dormID = dorm?.id {
                    recordCount =
                        try ElectricityRecordGRDB
                        .filter(ElectricityRecordGRDB.Columns.dormID == dormID)
                        .fetchCount(db)
                } else {
                    recordCount = 0
                }

                return (dorm, recordCount)
            }

            guard let dorm = state.0 else {
                electricityCacheDescription = "当前状态：未生成模拟宿舍"
                return
            }

            if let electricity = dorm.lastFetchElectricity, let date = dorm.lastFetchDate {
                electricityCacheDescription = "当前状态：\(dorm.campusName) · \(dorm.buildingName) · \(dorm.room)，\(state.1) 条记录，最新电量 \(String(format: "%.2f", electricity)) 度，最近更新 \(date.formatted(date: .abbreviated, time: .standard))"
            } else {
                electricityCacheDescription = "当前状态：\(dorm.campusName) · \(dorm.buildingName) · \(dorm.room)，\(state.1) 条记录，暂无最新电量"
            }
        } catch {
            electricityCacheDescription = "当前状态：读取失败"
        }
    }
}

private enum MockTodoAssignmentsFactory {
    static func makeTwoAssignmentsData(referenceDate: Date = .now) -> [TodoAssignmentsData] {
        [
            TodoAssignmentsData(
                course: .init(
                    id: "mock-course-todo-1",
                    name: "程序设计与算法分析",
                    number: "CS202",
                    department: "计算机学院",
                    teacher: "陈老师"
                ),
                assignments: [
                    .init(
                        id: 10001,
                        title: "实验报告：图的遍历",
                        publisher: "陈老师",
                        canSubmit: true,
                        submitStatus: false,
                        deadline: referenceDate.addingTimeInterval(6 * 3600),
                        startTime: referenceDate.addingTimeInterval(-2 * 24 * 3600)
                    )
                ]
            ),
            TodoAssignmentsData(
                course: .init(
                    id: "mock-course-todo-2",
                    name: "大学物理实验",
                    number: "PH114",
                    department: "理学院",
                    teacher: "刘老师"
                ),
                assignments: [
                    .init(
                        id: 10002,
                        title: "实验数据分析作业",
                        publisher: "刘老师",
                        canSubmit: true,
                        submitStatus: false,
                        deadline: referenceDate.addingTimeInterval(36 * 3600),
                        startTime: referenceDate.addingTimeInterval(-3 * 24 * 3600)
                    )
                ]
            ),
        ]
    }
}

private enum MockExamSchedulesFactory {
    static func makeFiveExamsData(referenceDate: Date = .now) -> [EduHelper.Exam] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: referenceDate)

        let todayExamStart = referenceDate
        let tomorrowExamStart = calendar.date(byAdding: .hour, value: 14, to: calendar.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart) ?? referenceDate
        let dayAfterTomorrowExamStart = calendar.date(byAdding: .hour, value: 14, to: calendar.date(byAdding: .day, value: 2, to: todayStart) ?? todayStart) ?? referenceDate
        let threeDaysLaterExamStart = calendar.date(byAdding: .hour, value: 14, to: calendar.date(byAdding: .day, value: 3, to: todayStart) ?? todayStart) ?? referenceDate
        let fiveDaysLaterExamStart = calendar.date(byAdding: .hour, value: 14, to: calendar.date(byAdding: .day, value: 5, to: todayStart) ?? todayStart) ?? referenceDate

        return [
            .init(
                campus: "云塘校区",
                session: "1",
                courseID: "EXAM-MOCK-001",
                courseName: "高等数学 B",
                teacher: "李老师",
                examTime: examTimeText(start: todayExamStart, durationHours: 2),
                examStartTime: todayExamStart,
                examEndTime: todayExamStart.addingTimeInterval(2 * 3600),
                examRoom: "文科楼 A-201",
                seatNumber: "",
                admissionTicketNumber: "",
                remarks: ""
            ),
            .init(
                campus: "云塘校区",
                session: "2",
                courseID: "EXAM-MOCK-002",
                courseName: "大学英语 IV",
                teacher: "周老师",
                examTime: examTimeText(start: tomorrowExamStart, durationHours: 2),
                examStartTime: tomorrowExamStart,
                examEndTime: tomorrowExamStart.addingTimeInterval(2 * 3600),
                examRoom: "综合实验楼 302",
                seatNumber: "",
                admissionTicketNumber: "",
                remarks: ""
            ),
            .init(
                campus: "云塘校区",
                session: "3",
                courseID: "EXAM-MOCK-003",
                courseName: "数据结构",
                teacher: "陈老师",
                examTime: examTimeText(start: dayAfterTomorrowExamStart, durationHours: 2),
                examStartTime: dayAfterTomorrowExamStart,
                examEndTime: dayAfterTomorrowExamStart.addingTimeInterval(2 * 3600),
                examRoom: "工科三号楼 105",
                seatNumber: "",
                admissionTicketNumber: "",
                remarks: ""
            ),
            .init(
                campus: "云塘校区",
                session: "4",
                courseID: "EXAM-MOCK-004",
                courseName: "马克思主义基本原理",
                teacher: "王老师",
                examTime: examTimeText(start: threeDaysLaterExamStart, durationHours: 2),
                examStartTime: threeDaysLaterExamStart,
                examEndTime: threeDaysLaterExamStart.addingTimeInterval(2 * 3600),
                examRoom: "文科楼 401",
                seatNumber: "",
                admissionTicketNumber: "",
                remarks: ""
            ),
            .init(
                campus: "云塘校区",
                session: "5",
                courseID: "EXAM-MOCK-005",
                courseName: "大学物理 B",
                teacher: "赵老师",
                examTime: examTimeText(start: fiveDaysLaterExamStart, durationHours: 2),
                examStartTime: fiveDaysLaterExamStart,
                examEndTime: fiveDaysLaterExamStart.addingTimeInterval(2 * 3600),
                examRoom: "工科一号楼 208",
                seatNumber: "",
                admissionTicketNumber: "",
                remarks: ""
            ),
        ]
    }

    private static func examTimeText(start: Date, durationHours: Int) -> String {
        let end = start.addingTimeInterval(TimeInterval(durationHours * 3600))
        return "\(start.formatted(date: .numeric, time: .shortened)) - \(end.formatted(date: .omitted, time: .shortened))"
    }
}

private enum MockCourseScheduleFactory {
    static func makeEmptyCourseScheduleData(referenceDate: Date = .now) -> CourseScheduleData {
        CourseScheduleData(
            semester: semesterText(),
            semesterStartDate: semesterStartDate(for: referenceDate),
            courses: [],
            remarks: []
        )
    }

    static func makeTodayFilledCourseScheduleData(referenceDate: Date = .now) -> CourseScheduleData {
        let today = CourseScheduleUtil.getDayOfWeek(referenceDate)
        let weeks = Array(1...16)

        let courses: [EduHelper.Course] = [
            .init(
                courseName: "高等数学 A(2)",
                groupName: "计算机类 2301",
                teacher: "李建华",
                sessions: [
                    .init(weeks: weeks, startSection: 1, endSection: 2, dayOfWeek: today, classroom: "云塘校区 综合教学楼 A-201")
                ]
            ),
            .init(
                courseName: "大学英语 III",
                groupName: "计算机类 2301",
                teacher: "周晓燕",
                sessions: [
                    .init(weeks: weeks, startSection: 3, endSection: 4, dayOfWeek: today, classroom: "云塘校区 文科楼 B-104")
                ]
            ),
            .init(
                courseName: "数据结构",
                groupName: "计算机科学与技术 2302",
                teacher: "陈志强",
                sessions: [
                    .init(weeks: weeks, startSection: 5, endSection: 6, dayOfWeek: today, classroom: "云塘校区 理科楼 C-305")
                ]
            ),
            .init(
                courseName: "中国近现代史纲要",
                groupName: "计算机类 2301",
                teacher: "王丽",
                sessions: [
                    .init(weeks: weeks, startSection: 7, endSection: 8, dayOfWeek: today, classroom: "云塘校区 综合教学楼 C-502")
                ]
            ),
            .init(
                courseName: "程序设计实践",
                groupName: "计算机科学与技术 2302",
                teacher: "刘洋",
                sessions: [
                    .init(weeks: weeks, startSection: 9, endSection: 10, dayOfWeek: today, classroom: "云塘校区 计算中心机房 402")
                ]
            ),
        ]

        return CourseScheduleData(
            semester: semesterText(),
            semesterStartDate: semesterStartDate(for: referenceDate),
            courses: courses,
            remarks: []
        )
    }

    static func makeTwoVisibleCourseScheduleData(referenceDate: Date = .now) throws -> CourseScheduleData {
        let semesterStartDate = semesterStartDate(for: referenceDate)
        guard
            let currentWeek = CourseScheduleUtil.getCurrentWeek(
                semesterStartDate: semesterStartDate,
                now: referenceDate
            )
        else {
            throw MockCourseScheduleError.currentWeekUnavailable
        }

        let today = CourseScheduleUtil.getDayOfWeek(referenceDate)
        let visibleSections = (1...CourseScheduleUtil.sectionTimeString.count).filter { section in
            let session = EduHelper.ScheduleSession(
                weeks: [currentWeek],
                startSection: section,
                endSection: section,
                dayOfWeek: today,
                classroom: nil
            )
            let dates = CourseScheduleUtil.getCourseEventDates(
                session: session,
                week: currentWeek,
                semesterStartDate: semesterStartDate
            )
            return referenceDate < dates.endDate
        }

        guard visibleSections.count >= 2 else {
            throw MockCourseScheduleError.insufficientVisibleSections
        }

        let courses = Array(visibleSections.prefix(2)).enumerated().map { index, section in
            EduHelper.Course(
                courseName: index == 0 ? "Java 课程设计" : "大数据存储与管理A",
                groupName: nil,
                teacher: index == 0 ? "徐聪讲师" : "刘文正 (08) 讲师",
                sessions: [
                    .init(
                        weeks: [currentWeek],
                        startSection: section,
                        endSection: section,
                        dayOfWeek: today,
                        classroom: index == 0 ? "金6-405" : "金12-209"
                    )
                ]
            )
        }

        return CourseScheduleData(
            semester: semesterText(),
            semesterStartDate: semesterStartDate,
            courses: courses,
            remarks: []
        )
    }

    static func makeConflictedCourseScheduleData(referenceDate: Date = .now) -> CourseScheduleData {
        let today = CourseScheduleUtil.getDayOfWeek(referenceDate)
        let weeks = Array(1...16)

        let courses: [EduHelper.Course] = [
            .init(
                courseName: "高等数学 A(2)",
                groupName: "计算机类 2301",
                teacher: "李建华",
                sessions: [
                    .init(weeks: weeks, startSection: 1, endSection: 2, dayOfWeek: today, classroom: "云塘校区 综合教学楼 A-201")
                ]
            ),
            .init(
                courseName: "大学英语 III",
                groupName: "计算机类 2301",
                teacher: "周晓燕",
                sessions: [
                    .init(weeks: weeks, startSection: 1, endSection: 4, dayOfWeek: today, classroom: "云塘校区 文科楼 B-104")
                ]
            ),
            .init(
                courseName: "数据结构",
                groupName: "计算机科学与技术 2302",
                teacher: "陈志强",
                sessions: [
                    .init(weeks: weeks, startSection: 5, endSection: 8, dayOfWeek: today, classroom: "云塘校区 理科楼 C-305")
                ]
            ),
            .init(
                courseName: "中国近现代史纲要",
                groupName: "计算机类 2301",
                teacher: "王丽",
                sessions: [
                    .init(weeks: weeks, startSection: 7, endSection: 9, dayOfWeek: today, classroom: "云塘校区 综合教学楼 C-502")
                ]
            ),
            .init(
                courseName: "操作系统",
                groupName: "计算机科学与技术 2302",
                teacher: "赵敏",
                sessions: [
                    .init(weeks: weeks, startSection: 9, endSection: 10, dayOfWeek: today, classroom: "云塘校区 理科楼 A-210")
                ]
            ),
        ]

        return CourseScheduleData(
            semester: semesterText(),
            semesterStartDate: semesterStartDate(for: referenceDate),
            courses: courses,
            remarks: []
        )
    }

    private static func semesterStartDate(for referenceDate: Date) -> Date {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: referenceDate)
        let weekday = calendar.component(.weekday, from: todayStart)
        let daysSinceSunday = weekday - 1
        return calendar.date(byAdding: .day, value: -daysSinceSunday, to: todayStart) ?? todayStart
    }

    private static func semesterText() -> String {
        "2026-2027-1"
    }
}

private enum MockElectricityFactory {
    static let campusName = "金盆岭"
    static let buildingName = "西苑11栋"
    static let room = "233"
    static let recordCount = 90

    static func replaceMockDormElectricity(in db: Database) throws {
        let existingDorm =
            try DormGRDB
            .filter(DormGRDB.Columns.campusName == campusName)
            .filter(DormGRDB.Columns.buildingName == buildingName)
            .filter(DormGRDB.Columns.room == room)
            .fetchOne(db)

        if let existingDorm, let dormID = existingDorm.id {
            try DormGRDB.deleteAllElectricityRecords(dormID: dormID, in: db)
        }

        var dorm: DormGRDB
        if let existingDorm {
            dorm = existingDorm
        } else {
            dorm = DormGRDB(
                id: nil,
                room: room,
                buildingName: buildingName,
                campusName: campusName,
                isFavorite: false,
                lastFetchDate: nil,
                lastFetchElectricity: nil
            )
            try dorm.insert(db)
        }

        let dormID: Int64
        if let existingID = dorm.id {
            dormID = existingID
        } else {
            dormID = db.lastInsertedRowID
            dorm.id = dormID
        }

        let records = makeRecords(dormID: dormID)
        for var record in records {
            try record.insert(db)
        }

        guard let latestRecord = records.last else {
            throw MockElectricityError.emptyRecords
        }
        dorm.lastFetchDate = latestRecord.date
        dorm.lastFetchElectricity = latestRecord.electricity
        try dorm.update(db)
    }

    static func makeRecords(
        dormID: Int64,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> [ElectricityRecordGRDB] {
        let todayStart = calendar.startOfDay(for: referenceDate)
        let rechargeDay = 55

        return (0..<recordCount).map { day in
            let date: Date
            if day == recordCount - 1 {
                date = referenceDate
            } else {
                let baseDate = calendar.date(byAdding: .day, value: day - (recordCount - 1), to: todayStart) ?? referenceDate
                date = calendar.date(byAdding: .hour, value: 20, to: baseDate) ?? baseDate
            }

            let rawValue: Double
            if day < rechargeDay {
                rawValue = 180 - Double(day) * 3
            } else if day == rechargeDay {
                rawValue = 160
            } else {
                rawValue = 160 - Double(day - rechargeDay) * 4
            }

            let jitter = Double((day * 37) % 9 - 4) * 0.1
            let electricity = ((rawValue + jitter) * 100).rounded() / 100

            return ElectricityRecordGRDB(
                id: nil,
                electricity: electricity,
                date: date,
                dormID: dormID
            )
        }
    }
}

private enum MockElectricityError: LocalizedError {
    case emptyRecords

    var errorDescription: String? {
        switch self {
        case .emptyRecords:
            return "模拟电量记录为空"
        }
    }
}

private enum MockCourseScheduleError: LocalizedError {
    case currentWeekUnavailable
    case insufficientVisibleSections

    var errorDescription: String? {
        switch self {
        case .currentWeekUnavailable:
            return "无法确定当前课表周次，不能生成模拟课表"
        case .insufficientVisibleSections:
            return "当前时间不足以生成两节仍可见的模拟课"
        }
    }
}
#endif
