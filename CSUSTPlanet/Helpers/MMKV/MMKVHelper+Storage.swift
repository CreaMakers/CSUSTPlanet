//
//  MMKVHelper+Storage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/4/11.
//

import CSUSTKit

extension MMKVHelper {
    enum TodoAssignments {
        @MMKVOptionalStorage(key: "TodoAssignments.cache")
        static var cache: Cached<[TodoAssignmentsData]>?
    }

    enum CourseGrades {
        @MMKVOptionalStorage(key: "Cached.courseGradesCache")
        static var cache: Cached<[EduHelper.CourseGrade]>?
    }

    enum CourseSchedule {
        @MMKVOptionalStorage(key: "Cached.courseScheduleCache")
        static var cache: Cached<CourseScheduleData>?

        /// 当前选择的课表 ID，nil 表示默认课表（学校课表）
        @MMKVOptionalStorage(key: "CourseSchedule.currentScheduleID")
        static var currentScheduleID: String?
    }

    enum PhysicsExperiment {
        @MMKVOptionalStorage(key: "Cached.physicsExperimentScheduleCache")
        static var scheduleCache: Cached<[PhysicsExperimentHelper.Course]>?
    }

    enum GlobalManager {
        @MMKVStorage(key: "GlobalVars.appearance", defaultValue: "system")
        static var appearance: String

        @MMKVStorage(key: "GlobalVars.isUserAgreementAccepted", defaultValue: false)
        static var isUserAgreementAccepted: Bool

        @MMKVStorage(key: "GlobalVars.isWebVPNModeEnabled", defaultValue: false)
        static var isWebVPNModeEnabled: Bool

        @MMKVStorage(key: "GlobalVars.hasCompletedOnboarding", defaultValue: false)
        static var hasCompletedOnboarding: Bool

        @MMKVOptionalStorage(key: "GlobalVars.ignoredAppUpdateVersionCode")
        static var ignoredAppUpdateVersionCode: Int?
    }

    enum WidgetSettings {
        enum DormElectricity {
            @MMKVStorage(key: "WidgetSettings.DormElectricity.isAutoRefresh", defaultValue: true)
            static var isAutoRefresh: Bool

            @MMKVStorage(key: "WidgetSettings.DormElectricity.refreshFrequency", defaultValue: 1)
            static var refreshFrequency: Int
        }

        enum GradeAnalysis {
            @MMKVStorage(key: "WidgetSettings.GradeAnalysis.isAutoRefresh", defaultValue: true)
            static var isAutoRefresh: Bool

            @MMKVStorage(key: "WidgetSettings.GradeAnalysis.refreshFrequency", defaultValue: 1)
            static var refreshFrequency: Int
        }

        enum TodoAssignments {
            @MMKVStorage(key: "WidgetSettings.TodoAssignments.isAutoRefresh", defaultValue: true)
            static var isAutoRefresh: Bool

            @MMKVStorage(key: "WidgetSettings.TodoAssignments.refreshFrequency", defaultValue: 1)
            static var refreshFrequency: Int
        }
    }
}
