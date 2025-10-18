//
//  ActivityManager.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/15.
//

import ActivityKit
import Foundation

class ActivityManager {
    static let shared = ActivityManager()

    var activity: Activity<CourseStatusWidgetAttributes>? = nil

    private init() {}

    func setup() {
        guard activity == nil else { return }
        guard let existingActivity = Activity<CourseStatusWidgetAttributes>.activities.first else { return }
        activity = existingActivity
    }

    private func startActivity(_ attributes: CourseStatusWidgetAttributes) throws {
        let contentState = CourseStatusWidgetAttributes.ContentState()

        let activity = try Activity.request(
            attributes: attributes,
            content: .init(state: contentState, staleDate: nil)
        )
        self.activity = activity
        scheduleUpdateTasks(for: activity, attributes: attributes)
    }

    private func getCourseDates(from startSection: Int, to endSection: Int, now: Date) -> (startDate: Date, endDate: Date)? {
        let calendar = Calendar.current

        let startIndex = startSection - 1
        let endIndex = endSection - 1

        guard startIndex >= 0, startIndex < CourseScheduleHelper.sectionTimeString.count,
            endIndex >= 0, endIndex < CourseScheduleHelper.sectionTimeString.count
        else {
            return nil
        }

        let startTimeString = CourseScheduleHelper.sectionTimeString[startIndex].0
        let endTimeString = CourseScheduleHelper.sectionTimeString[endIndex].1

        let startComponents = startTimeString.split(separator: ":").compactMap { Int($0) }
        guard startComponents.count == 2 else { return nil }
        let startHour = startComponents[0]
        let startMinute = startComponents[1]

        let endComponents = endTimeString.split(separator: ":").compactMap { Int($0) }
        guard endComponents.count == 2 else { return nil }
        let endHour = endComponents[0]
        let endMinute = endComponents[1]

        guard let startDate = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: now),
            let endDate = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: now)
        else {
            return nil
        }

        return (startDate, endDate)
    }

    func startActivityIfNeed() {
        // #if DEBUG
        //     let currentDate = {
        //         let dateFormatter = DateFormatter()
        //         dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        //         return dateFormatter.date(from: "2025-10-20 10:08")!
        //     }()
        // #else
        let currentDate = Date()
        // #endif

        guard let data = MMKVManager.shared.courseScheduleCache else { return }
        guard let courseDisplayInfo = CourseScheduleHelper.getCurrentCourseForStatus(semesterStartDate: data.value.semesterStartDate, now: currentDate, courses: data.value.courses) else { return }
        debugPrint("Starting Course Status Live Activity for course: \(courseDisplayInfo.course.courseName)")
        guard let courseDates = getCourseDates(from: courseDisplayInfo.session.startSection, to: courseDisplayInfo.session.endSection, now: currentDate) else { return }
        let attributes = CourseStatusWidgetAttributes(
            courseName: courseDisplayInfo.course.courseName,
            teacher: courseDisplayInfo.course.teacher,
            classroom: courseDisplayInfo.session.classroom,
            startDate: courseDates.startDate,
            endDate: courseDates.endDate
        )
        try? startActivity(attributes)
    }

    private func stopActivity() {
        guard let activity = activity else { return }
        guard activity.activityState == .active else {
            self.activity = nil
            return
        }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            self.activity = nil
        }
    }

    private func scheduleUpdateTasks(for activity: Activity<CourseStatusWidgetAttributes>, attributes: CourseStatusWidgetAttributes) {
        Task {
            let sleepDuration = attributes.startDate.timeIntervalSinceNow
            guard sleepDuration > 0 else { return }
            try? await Task.sleep(for: .seconds(sleepDuration))
            guard activity.activityState == .active else { return }
            await activity.update(.init(state: .init(), staleDate: nil))
        }

        Task {
            let sleepDuration = attributes.endDate.timeIntervalSinceNow
            guard sleepDuration > 0 else { return }
            try? await Task.sleep(for: .seconds(sleepDuration))
            guard activity.activityState == .active else { return }
            await activity.update(.init(state: .init(), staleDate: nil))
        }
    }

    @MainActor
    func onLiveActivitySettingChanged(oldValue: Bool, newValue: Bool) {
        if GlobalVars.shared.isLiveActivityEnabled {
            startActivityIfNeed()
        } else {
            stopActivity()
        }
    }
}
