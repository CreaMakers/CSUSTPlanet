//
//  ScheduleEventStore.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/9/4.
//

import CSUSTKit
import Combine
import Foundation
import GRDB

/// 统一订阅日程相关数据源，并向外提供日程事件快照
@MainActor
final class ScheduleEventStore {
    static let shared = ScheduleEventStore()

    private let eventsSubject = CurrentValueSubject<[ScheduleEvent]?, Never>(nil)
    private var cancellables = Set<AnyCancellable>()
    private var electricityObservation: (any DatabaseCancellable)?

    private var eventsByKind: [ScheduleEventKind: [ScheduleEvent]] = [:]
    private let initialEventKinds: Set<ScheduleEventKind> = [
        .course,
        .exam,
        .assignment,
        .electricity,
    ]
    private var receivedInitialEventKinds: Set<ScheduleEventKind> = []
    private var publishedEvents: [ScheduleEvent]?

    var eventsPublisher: AnyPublisher<[ScheduleEvent], Never> {
        eventsSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    private init() {
        subscribeToCaches()
        subscribeToElectricity()
    }

    // MARK: - Subscriptions

    private func subscribeToCaches() {
        MMKVHelper.CourseSchedule.$activeCourseSchedule
            .receive(on: RunLoop.main)
            .sink { [weak self] cached in
                guard let self else { return }
                self.replaceEvents(
                    for: .course,
                    with: Self.makeCourseEvents(from: cached?.value)
                )
            }
            .store(in: &cancellables)

        MMKVHelper.ExamSchedule.$cache
            .receive(on: RunLoop.main)
            .sink { [weak self] cached in
                guard let self else { return }
                self.replaceEvents(
                    for: .exam,
                    with: Self.makeExamEvents(from: cached?.value ?? [])
                )
            }
            .store(in: &cancellables)

        MMKVHelper.TodoAssignments.$cache
            .receive(on: RunLoop.main)
            .sink { [weak self] cached in
                guard let self else { return }
                self.replaceEvents(
                    for: .assignment,
                    with: Self.makeAssignmentEvents(from: cached?.value ?? [])
                )
            }
            .store(in: &cancellables)
    }

    private func subscribeToElectricity() {
        GRDBIPCNotifier.shared.dbChangedSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.restartElectricityObservation()
            }
            .store(in: &cancellables)

        restartElectricityObservation()
    }

    private func restartElectricityObservation() {
        electricityObservation?.cancel()

        guard let pool = DatabaseManager.shared.pool else {
            replaceEvents(for: .electricity, with: [])
            return
        }

        let observation = ValueObservation.tracking { db -> (DormGRDB?, [ElectricityRecordGRDB]) in
            let dorm =
                try DormGRDB
                .filter(DormGRDB.Columns.isFavorite == true)
                .fetchOne(db)
                ?? DormGRDB.order(DormGRDB.Columns.id.asc).fetchOne(db)

            guard let dormID = dorm?.id else {
                return (dorm, [])
            }

            let records =
                try ElectricityRecordGRDB
                .filter(ElectricityRecordGRDB.Columns.dormID == dormID)
                .filter(ElectricityRecordGRDB.Columns.date >= ElectricityUtil.recentRecordsStartDate())
                .order(ElectricityRecordGRDB.Columns.date.asc)
                .fetchAll(db)

            return (dorm, records)
        }

        electricityObservation = observation.start(
            in: pool,
            scheduling: .immediate,
            onError: { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.replaceEvents(for: .electricity, with: [])
                }
            },
            onChange: { [weak self] data in
                let (dorm, records) = data
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.replaceEvents(
                        for: .electricity,
                        with: Self.makeElectricityEvents(
                            from: dorm,
                            records: records,
                        )
                    )
                }
            }
        )
    }

    // MARK: - Event Updates

    private func replaceEvents(for kind: ScheduleEventKind, with events: [ScheduleEvent]) {
        eventsByKind[kind] = events
        receivedInitialEventKinds.insert(kind)

        guard receivedInitialEventKinds == initialEventKinds else {
            return
        }

        var eventsByID: [String: ScheduleEvent] = [:]
        for event in eventsByKind.values.flatMap({ $0 }) {
            eventsByID[event.id] = event
        }

        let events = eventsByID.values.map { $0 }.sorted(by: { (lhs: ScheduleEvent, rhs: ScheduleEvent) -> Bool in
            if lhs.timing.anchorDate != rhs.timing.anchorDate {
                return lhs.timing.anchorDate < rhs.timing.anchorDate
            }
            if lhs.kind.rawValue != rhs.kind.rawValue {
                return lhs.kind.rawValue < rhs.kind.rawValue
            }
            return lhs.id < rhs.id
        })

        guard publishedEvents != events else { return }
        publishedEvents = events
        eventsSubject.send(events)
    }

    // MARK: - Event Conversion

    private static func makeCourseEvents(from schedule: ActiveCourseSchedule?) -> [ScheduleEvent] {
        guard let schedule, let data = schedule.data else { return [] }

        let weekCount = CourseScheduleUtil.resolveWeekCount(data.weekCount)
        guard weekCount > 0 else { return [] }

        let scheduleKey: String
        if schedule.isCustomSchedule {
            let customScheduleKey = MMKVHelper.CourseSchedule.currentScheduleID ?? schedule.scheduleName ?? "unknown"
            scheduleKey = "custom:\(customScheduleKey)"
        } else {
            scheduleKey = "default:\(data.semester ?? "unknown")"
        }

        var events: [ScheduleEvent] = []

        for (courseIndex, course) in data.courses.enumerated() {
            let courseKey = [
                String(courseIndex),
                course.courseName,
                course.groupName ?? "",
                course.teacher ?? "",
            ].joined(separator: ":")

            for (sessionIndex, session) in course.sessions.enumerated() {
                let sectionCount = CourseScheduleUtil.sectionTimeString.count
                guard
                    session.startSection >= 1,
                    session.startSection <= session.endSection,
                    session.endSection <= sectionCount
                else {
                    continue
                }

                let sessionKey = [
                    String(sessionIndex),
                    String(session.dayOfWeek.rawValue),
                    String(session.startSection),
                    String(session.endSection),
                    session.classroom ?? "",
                    session.weeks.sorted().map(String.init).joined(separator: ","),
                ].joined(separator: ":")

                for week in Set(session.weeks).filter({ (1...weekCount).contains($0) }).sorted() {
                    let dates = CourseScheduleUtil.getCourseEventDates(
                        session: session,
                        week: week,
                        semesterStartDate: data.semesterStartDate
                    )

                    let details = [
                        detail("课表", schedule.scheduleName),
                        detail("周次", "第 " + String(week) + " 周"),
                        detail("星期", session.dayOfWeek.chineseLongString),
                        detail(
                            "节次",
                            "第 " + String(session.startSection) + "-" + String(session.endSection) + " 节"
                        ),
                        detail("分组", course.groupName),
                    ].compactMap { $0 }

                    events.append(
                        ScheduleEvent(
                            id: stableID([
                                "course",
                                scheduleKey,
                                courseKey,
                                sessionKey,
                                "week-" + String(week),
                            ]),
                            kind: .course,
                            timing: .interval(start: dates.startDate, end: dates.endDate),
                            content: ScheduleEventContent(
                                title: course.courseName,
                                subtitle: course.teacher,
                                location: session.classroom,
                                details: details
                            )
                        )
                    )
                }
            }
        }

        return events
    }

    private static func makeExamEvents(from exams: [EduHelper.Exam]) -> [ScheduleEvent] {
        exams.compactMap { exam in
            guard exam.examEndTime > exam.examStartTime else { return nil }

            let details = [
                detail("校区", exam.campus),
                detail("场次", exam.session),
                detail("考试时间", exam.examTime),
                detail("座位号", exam.seatNumber),
                detail("准考证号", exam.admissionTicketNumber),
                detail("备注", exam.remarks),
            ].compactMap { $0 }

            return ScheduleEvent(
                id: stableID([
                    "exam",
                    exam.courseID,
                    exam.session,
                    exam.examStartTime.timeIntervalSince1970.description,
                    exam.examEndTime.timeIntervalSince1970.description,
                    exam.examRoom,
                ]),
                kind: .exam,
                timing: .interval(start: exam.examStartTime, end: exam.examEndTime),
                content: ScheduleEventContent(
                    title: "考试：" + exam.courseName,
                    subtitle: exam.teacher.nilIfEmpty,
                    location: exam.examRoom.nilIfEmpty,
                    details: details
                )
            )
        }
    }

    private static func makeAssignmentEvents(from groups: [TodoAssignmentsData]) -> [ScheduleEvent] {
        groups.flatMap { group in
            group.assignments.compactMap { assignment in
                guard assignment.canSubmit, !assignment.submitStatus else {
                    return nil
                }

                let details = [
                    detail("发布人", assignment.publisher),
                    detail("开始提交", formattedDate(assignment.startTime)),
                    detail("状态", "待提交"),
                ].compactMap { $0 }

                return ScheduleEvent(
                    id: stableID([
                        "assignment",
                        group.course.id,
                        String(assignment.id),
                    ]),
                    kind: .assignment,
                    timing: .point(at: assignment.deadline),
                    content: ScheduleEventContent(
                        title: assignment.title,
                        subtitle: group.course.name.nilIfEmpty,
                        location: nil,
                        details: details
                    )
                )
            }
        }
    }

    private static func makeElectricityEvents(from dorm: DormGRDB?, records: [ElectricityRecordGRDB]) -> [ScheduleEvent] {
        guard
            let dorm,
            let dormID = dorm.id,
            let predictionDate = ElectricityUtil.predictExhaustionDate(from: records)
        else {
            return []
        }

        let dormName = [dorm.campusName, dorm.buildingName, dorm.room]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
        let latestElectricity = dorm.lastFetchElectricity ?? records.last?.electricity
        let lastObservationAt = dorm.lastFetchDate ?? records.last?.date

        let details = [
            detail("当前电量", latestElectricity.map { String(format: "%.2f 度", $0) }),
            detail("最近更新", lastObservationAt.map(formattedDate)),
        ].compactMap { $0 }

        return [
            ScheduleEvent(
                id: stableID(["electricity", String(dormID)]),
                kind: .electricity,
                timing: .point(at: predictionDate),
                content: ScheduleEventContent(
                    title: "电量预计耗尽",
                    subtitle: dormName.nilIfEmpty,
                    location: nil,
                    details: details
                )
            )
        ]
    }

    // MARK: - Helpers

    private static func stableID(_ components: [String]) -> String {
        components.map { "\($0.count):\($0)" }.joined(separator: "|")
    }

    private static func detail(_ label: String, _ value: String?) -> ScheduleEventDetail? {
        guard let value = value?.nilIfEmpty else { return nil }
        return ScheduleEventDetail(label: label, value: value)
    }

    private static func formattedDate(_ date: Date) -> String {
        date.formatted(.dateTime.year().month().day().hour().minute())
    }
}
