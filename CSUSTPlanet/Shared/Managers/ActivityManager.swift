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
        guard let existingActivity = Activity<CourseStatusWidgetAttributes>.activities.first else {
            return
        }
        activity = existingActivity
    }

    func startActivity() throws {
        let attributes = CourseStatusWidgetAttributes.preview
        let contentState = CourseStatusWidgetAttributes.ContentState()

        let activity = try Activity.request(
            attributes: attributes,
            content: .init(state: contentState, staleDate: nil)
        )
        self.activity = activity
    }

    func stopActivity() {
        guard let activity = activity else {
            return
        }
        guard activity.activityState == .active else {
            self.activity = nil
            return
        }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            self.activity = nil
        }
    }
}
