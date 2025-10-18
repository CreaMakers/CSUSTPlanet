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
        guard activity == nil, let existingActivity = Activity<CourseStatusWidgetAttributes>.activities.first else { return }
        self.activity = existingActivity
        debugPrint("Restored an existing Live Activity.")
        Task {
            await autoUpdateActivity()
        }
    }

    @MainActor
    func autoUpdateActivity() {
        guard GlobalVars.shared.isLiveActivityEnabled else {
            debugPrint("Live Activity is disabled. Stopping any active activity.")
            stopActivity()
            return
        }

        let currentDate = Date()
        guard let data = MMKVManager.shared.courseScheduleCache else {
            stopActivity()
            return
        }

        if let courseDisplayInfo = CourseScheduleHelper.getRelevantCourseForStatus(
            semesterStartDate: data.value.semesterStartDate,
            now: currentDate,
            courses: data.value.courses
        ), let courseDates = getCourseDates(from: courseDisplayInfo.session.startSection, to: courseDisplayInfo.session.endSection, now: currentDate) {

            let attributes = CourseStatusWidgetAttributes(
                courseName: courseDisplayInfo.course.courseName,
                teacher: courseDisplayInfo.course.teacher,
                classroom: courseDisplayInfo.session.classroom,
                startDate: courseDates.startDate,
                endDate: courseDates.endDate
            )

            if let existingActivity = self.activity, existingActivity.activityState == .active {
                if existingActivity.attributes == attributes {
                    debugPrint("Live Activity is correct. Forcing a UI refresh.")
                    Task {
                        let content = ActivityContent(state: CourseStatusWidgetAttributes.ContentState(), staleDate: nil)
                        await existingActivity.update(content)
                    }
                } else {
                    debugPrint("Stale activity found. Replacing it with the new one.")
                    try? startActivity(attributes)
                }
            } else {
                debugPrint("No active activity found. Starting a new one.")
                try? startActivity(attributes)
            }
        } else {
            debugPrint("No relevant course found. Stopping any active activity.")
            stopActivity()
        }
    }

    private func startActivity(_ attributes: CourseStatusWidgetAttributes) throws {
        stopActivity()

        let content = ActivityContent(state: CourseStatusWidgetAttributes.ContentState(), staleDate: nil)

        let newActivity = try Activity.request(
            attributes: attributes,
            content: content
        )
        self.activity = newActivity
        debugPrint("Live Activity started for course: \(attributes.courseName)")
    }

    private func stopActivity() {
        guard let activityToStop = activity else { return }

        Task {
            await activityToStop.end(nil, dismissalPolicy: .immediate)
            if self.activity?.id == activityToStop.id {
                self.activity = nil
                debugPrint("Live Activity stopped.")
            }
        }
    }

    private func getCourseDates(from startSection: Int, to endSection: Int, now: Date) -> (startDate: Date, endDate: Date)? {
        let calendar = Calendar.current
        let startIndex = startSection - 1
        let endIndex = endSection - 1
        guard startIndex >= 0, startIndex < CourseScheduleHelper.sectionTimeString.count,
            endIndex >= 0, endIndex < CourseScheduleHelper.sectionTimeString.count
        else { return nil }
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
        else { return nil }
        return (startDate, endDate)
    }
}
