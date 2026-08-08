//
//  CourseOverviewViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import Combine
import Foundation
import SwiftUI

@MainActor
@Observable
final class CourseOverviewViewModel {
    enum CourseDisplayState {
        case loading
        case beforeSemester(days: Int?)
        case inSemester(dailyCourseState: DailyCourseDisplayState)
        case afterSemester
    }

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    private var activeCourseSchedule: Cached<ActiveCourseSchedule>?

    init() {
        MMKVHelper.CourseSchedule.$activeCourseSchedule
            .receive(on: DispatchQueue.main)
            .sink { [weak self] schedule in
                self?.activeCourseSchedule = schedule
            }
            .store(in: &cancellables)
    }

    func courseDisplayState(at now: Date) -> CourseDisplayState {
        guard let data = activeCourseSchedule?.value.data else { return .loading }

        let status = CourseScheduleUtil.getSemesterStatus(semesterStartDate: data.semesterStartDate, date: now, weekCount: data.weekCount)

        switch status {
        case .beforeSemester:
            let days = CourseScheduleUtil.getDaysUntilSemesterStart(semesterStartDate: data.semesterStartDate, currentDate: now)
            return .beforeSemester(days: days)
        case .afterSemester:
            return .afterSemester
        case .inSemester:
            let dailyCourseState = CourseScheduleUtil.getDailyCourseDisplayState(
                semesterStartDate: data.semesterStartDate,
                now: now,
                courses: data.courses,
                weekCount: data.weekCount
            )
            return .inSemester(dailyCourseState: dailyCourseState)
        }
    }

    var semesterInfoText: String {
        guard let scheduleName = activeCourseSchedule?.value.scheduleName else { return "默认学期" }
        return scheduleName
    }
}
