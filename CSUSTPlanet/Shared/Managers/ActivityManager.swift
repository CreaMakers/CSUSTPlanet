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

    func startActivity() throws {
        let attributes = CourseStatusWidgetAttributes.preview
        let contentState = CourseStatusWidgetAttributes.ContentState()

        let activity = try Activity.request(
            attributes: attributes,
            content: .init(state: contentState, staleDate: attributes.startDate)
        )
        self.activity = activity
        scheduleUpdateTasks(for: activity, attributes: attributes)
    }

    func stopActivity() {
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
            await activity.update(.init(state: .init(), staleDate: attributes.endDate))
        }

        Task {
            let sleepDuration = attributes.endDate.timeIntervalSinceNow
            guard sleepDuration > 0 else { return }
            try? await Task.sleep(for: .seconds(sleepDuration))
            guard activity.activityState == .active else { return }
            await activity.update(.init(state: .init(), staleDate: nil))
        }
    }
}
