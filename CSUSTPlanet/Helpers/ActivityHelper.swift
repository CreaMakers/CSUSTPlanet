//
//  ActivityHelper.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/15.
//

import ActivityKit
import Foundation
import OSLog

class ActivityHelper {
    static let shared = ActivityHelper()

    var activity: Activity<CourseStatusWidgetAttributes>? = nil

    private init() {}

    func setup() {
        guard activity == nil, let existingActivity = Activity<CourseStatusWidgetAttributes>.activities.first else { return }
        self.activity = existingActivity

        Logger.activityHelper.info("已恢复现有的实时活动")
        Task {
            await autoUpdateActivity()
        }
    }

    @MainActor
    func autoUpdateActivity() {
        guard GlobalManager.shared.isLiveActivityEnabled else {
            Logger.activityHelper.info("实时活动已禁用。正在停止所有活跃活动")
            stopActivity()
            return
        }

        let currentDate = Date()
        guard let data = MMKVHelper.shared.courseScheduleCache else {
            stopActivity()
            return
        }

        if let courseDisplayInfo = CourseScheduleUtil.getRelevantCourseForStatus(
            semesterStartDate: data.value.semesterStartDate,
            now: currentDate,
            courses: data.value.courses
        ), let courseDates = getCourseDates(from: courseDisplayInfo.session.startSection, to: courseDisplayInfo.session.endSection, now: currentDate) {

            let attributes = CourseStatusWidgetAttributes(
                courseName: courseDisplayInfo.course.courseName,
                teacher: courseDisplayInfo.course.teacher ?? "无老师",
                classroom: courseDisplayInfo.session.classroom,
                startDate: courseDates.startDate,
                endDate: courseDates.endDate
            )

            if let existingActivity = self.activity, existingActivity.activityState == .active {
                if existingActivity.attributes == attributes {
                    Logger.activityHelper.info("实时活动状态正确。正在强制刷新 UI")
                    Task {
                        let content = ActivityContent(state: CourseStatusWidgetAttributes.ContentState(now: .now), staleDate: nil)
                        await existingActivity.update(content)
                    }
                } else {
                    Logger.activityHelper.info("发现过期的活动。正在替换为新活动")
                    try? startActivity(attributes)
                }
            } else {
                Logger.activityHelper.info("未找到活跃活动。正在启动新活动")
                try? startActivity(attributes)
            }
        } else {
            Logger.activityHelper.info("未找到相关课程。正在停止所有活跃活动")
            stopActivity()
        }
    }

    private func startActivity(_ attributes: CourseStatusWidgetAttributes) throws {
        stopActivity()

        let content = ActivityContent(state: CourseStatusWidgetAttributes.ContentState(now: .now), staleDate: nil)

        let newActivity = try Activity.request(
            attributes: attributes,
            content: content
        )
        self.activity = newActivity
        Logger.activityHelper.info("已为课程启动实时活动：\(attributes.courseName)")
    }

    private func stopActivity() {
        guard let activityToStop = activity else { return }

        Task {
            await activityToStop.end(nil, dismissalPolicy: .immediate)
            if self.activity?.id == activityToStop.id {
                self.activity = nil
                Logger.activityHelper.info("实时活动已停止")
            }
        }
    }

    private func getCourseDates(from startSection: Int, to endSection: Int, now: Date) -> (startDate: Date, endDate: Date)? {
        let calendar = Calendar.current
        let startIndex = startSection - 1
        let endIndex = endSection - 1
        guard startIndex >= 0, startIndex < CourseScheduleUtil.sectionTimeString.count,
            endIndex >= 0, endIndex < CourseScheduleUtil.sectionTimeString.count
        else { return nil }
        let startTimeString = CourseScheduleUtil.sectionTimeString[startIndex].0
        let endTimeString = CourseScheduleUtil.sectionTimeString[endIndex].1
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
