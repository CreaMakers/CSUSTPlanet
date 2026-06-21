//
//  AppRoute.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/4/12.
//

import CSUSTKit
import Foundation
import SwiftUI

enum AppRoute: Hashable {
    case overview(OverviewRoute)
    case features(FeaturesRoute)
    case profile(ProfileRoute)

    var trackSegment: String {
        switch self {
        case .overview(let route):
            return route.trackSegment
        case .features(let route):
            return route.trackSegment
        case .profile(let route):
            return route.trackSegment
        }
    }

    @ViewBuilder
    var destinationView: some View {
        switch self {
        case .overview(let route):
            route.destinationView
        case .features(let route):
            route.destinationView
        case .profile(let route):
            route.destinationView
        }
    }

    // MARK: - OverviewRoute

    enum OverviewRoute: Hashable {
        case announcementList(viewModel: AnnouncementListViewModel)

        var trackSegment: String {
            switch self {
            case .announcementList:
                return "AnnouncementList"
            }
        }

        @ViewBuilder
        var destinationView: some View {
            switch self {
            case .announcementList(let viewModel):
                AnnouncementListView(viewModel: viewModel)
            }
        }
    }

    // MARK: - FeaturesRoute

    enum FeaturesRoute: Hashable {
        case education(EducationRoute)
        case mooc(MoocRoute)
        case campusTool(CampusToolRoute)
        case physicsExperiment(PhysicsExperimentRoute)
        case examQuery(ExamQueryRoute)

        var trackSegment: String {
            switch self {
            case .education(let route):
                return route.trackSegment
            case .mooc(let route):
                return route.trackSegment
            case .campusTool(let route):
                return route.trackSegment
            case .physicsExperiment(let route):
                return route.trackSegment
            case .examQuery(let route):
                return route.trackSegment
            }
        }

        @ViewBuilder
        var destinationView: some View {
            switch self {
            case .education(let route):
                route.destinationView
            case .mooc(let route):
                route.destinationView
            case .campusTool(let route):
                route.destinationView
            case .physicsExperiment(let route):
                route.destinationView
            case .examQuery(let route):
                route.destinationView
            }
        }

        enum EducationRoute: Hashable {
            case courseSchedule
            case gradeQuery(GradeQueryRoute)
            case examSchedule
            case gradeAnalysis

            var trackSegment: String {
                switch self {
                case .courseSchedule:
                    return "CourseSchedule"
                case .gradeQuery(let route):
                    return route.trackSegment
                case .examSchedule:
                    return "ExamSchedule"
                case .gradeAnalysis:
                    return "GradeAnalysis"
                }
            }

            @ViewBuilder
            var destinationView: some View {
                switch self {
                case .courseSchedule:
                    CourseScheduleView()
                case .gradeQuery(let route):
                    route.destinationView
                case .examSchedule:
                    ExamScheduleView()
                case .gradeAnalysis:
                    GradeAnalysisView()
                }
            }

            enum GradeQueryRoute: Hashable {
                case main
                case detail(EduHelper.CourseGrade)

                var trackSegment: String {
                    switch self {
                    case .main:
                        return "GradeQuery"
                    case .detail:
                        return "GradeDetail"
                    }
                }

                @ViewBuilder
                var destinationView: some View {
                    switch self {
                    case .main:
                        GradeQueryView()
                    case .detail(let courseGrade):
                        GradeDetailView(courseGrade: courseGrade)
                    }
                }
            }
        }

        enum MoocRoute: Hashable {
            case courses(CoursesRoute)
            case todoAssignments

            var trackSegment: String {
                switch self {
                case .courses(let route):
                    return route.trackSegment
                case .todoAssignments:
                    return "TodoAssignments"
                }
            }

            @ViewBuilder
            var destinationView: some View {
                switch self {
                case .courses(let route):
                    route.destinationView
                case .todoAssignments:
                    AssignmentsView()
                }
            }

            enum CoursesRoute: Hashable {
                case main
                case detail(MoocHelper.Course)

                var trackSegment: String {
                    switch self {
                    case .main:
                        return "Courses"
                    case .detail:
                        return "CourseDetail"
                    }
                }

                @ViewBuilder
                var destinationView: some View {
                    switch self {
                    case .main:
                        CoursesView()
                    case .detail(let course):
                        CourseDetailView(course: course)
                    }
                }
            }
        }

        enum CampusToolRoute: Hashable {
            case dormList(DormListRoute)
            case availableClassroom
            case campusMap
            case schoolCalendarList(SchoolCalendarListRoute)
            case electricityRecharge
            case webVPNConverter
            case eval

            var trackSegment: String {
                switch self {
                case .dormList(let route):
                    return route.trackSegment
                case .availableClassroom:
                    return "AvailableClassroom"
                case .campusMap:
                    return "CampusMap"
                case .schoolCalendarList(let route):
                    return route.trackSegment
                case .electricityRecharge:
                    return "ElectricityRecharge"
                case .webVPNConverter:
                    return "WebVPNConverter"
                case .eval:
                    return "Eval"
                }
            }

            @ViewBuilder
            var destinationView: some View {
                switch self {
                case .dormList(let route):
                    route.destinationView
                case .availableClassroom:
                    AvailableClassroomView()
                case .campusMap:
                    CampusMapView()
                case .schoolCalendarList(let route):
                    route.destinationView
                case .electricityRecharge:
                    ElectricityRechargeView()
                case .webVPNConverter:
                    WebVPNConverterView()
                case .eval:
                    EvalView()
                }
            }

            enum DormListRoute: Hashable {
                case main
                case detail(DormDetailRoute)

                var trackSegment: String {
                    switch self {
                    case .main:
                        return "DormList"
                    case .detail(let route):
                        return route.trackSegment
                    }
                }

                @ViewBuilder
                var destinationView: some View {
                    switch self {
                    case .main:
                        DormListView()
                    case .detail(let route):
                        route.destinationView
                    }
                }

                enum DormDetailRoute: Hashable {
                    case main(DormGRDB)
                    case history(DormDetailViewModel)

                    var trackSegment: String {
                        switch self {
                        case .main:
                            return "DormDetail"
                        case .history:
                            return "DormHistory"
                        }
                    }

                    @ViewBuilder
                    var destinationView: some View {
                        switch self {
                        case .main(let dorm):
                            DormDetailView(dorm: dorm)
                        case .history(let viewModel):
                            DormHistoryView(viewModel: viewModel)
                        }
                    }
                }
            }

            enum SchoolCalendarListRoute: Hashable {
                case main
                case detail(SchoolCalendar)

                var trackSegment: String {
                    switch self {
                    case .main:
                        return "SchoolCalendarList"
                    case .detail:
                        return "SchoolCalendar"
                    }
                }

                @ViewBuilder
                var destinationView: some View {
                    switch self {
                    case .main:
                        SchoolCalendarListView()
                    case .detail(let calendar):
                        SchoolCalendarView(schoolCalendar: calendar)
                    }
                }
            }
        }

        enum PhysicsExperimentRoute: Hashable {
            case schedule
            case grade

            var trackSegment: String {
                switch self {
                case .schedule:
                    return "PhysicsExperimentSchedule"
                case .grade:
                    return "PhysicsExperimentGrade"
                }
            }

            @ViewBuilder
            var destinationView: some View {
                switch self {
                case .schedule:
                    PhysicsExperimentScheduleView()
                case .grade:
                    PhysicsExperimentGradeView()
                }
            }
        }

        enum ExamQueryRoute: Hashable {
            case cet
            case mandarin
            case ncre

            var trackSegment: String {
                switch self {
                case .cet:
                    return "CET"
                case .mandarin:
                    return "Mandarin"
                case .ncre:
                    return "NCRE"
                }
            }

            @ViewBuilder
            var destinationView: some View {
                switch self {
                case .cet:
                    CETView()
                case .mandarin:
                    MandarinView()
                case .ncre:
                    NCREView()
                }
            }
        }
    }

    // MARK: - ProfileRoute

    enum ProfileRoute: Hashable {
        case profileDetail
        case networkSettings
        case backgroundTaskSettings
        case notificationSettings
        case widgetSettings
        case about(AboutRoute)
        case feedback
        case userAgreement

        var trackSegment: String {
            switch self {
            case .profileDetail:
                return "ProfileDetail"
            case .networkSettings:
                return "NetworkSettings"
            case .backgroundTaskSettings:
                return "BackgroundTaskSettings"
            case .notificationSettings:
                return "NotificationSettings"
            case .widgetSettings:
                return "WidgetSettings"
            case .about(let route):
                return route.trackSegment
            case .feedback:
                return "Feedback"
            case .userAgreement:
                return "UserAgreement"
            }
        }

        @ViewBuilder
        var destinationView: some View {
            switch self {
            case .profileDetail:
                ProfileDetailView()
            case .networkSettings:
                NetworkSettingsView()
            case .backgroundTaskSettings:
                #if os(iOS)
                BackgroundTaskSettingsView()
                #else
                EmptyView()
                #endif
            case .notificationSettings:
                NotificationSettingsView()
            case .widgetSettings:
                WidgetSettingsView()
            case .about(let route):
                route.destinationView
            case .feedback:
                FeedbackView()
            case .userAgreement:
                UserAgreementView(isButtonPresented: false)
            }
        }

        enum AboutRoute: Hashable {
            case main
            case openSourceLicenses(OpenSourceLicensesRoute)

            var trackSegment: String {
                switch self {
                case .main:
                    return "About"
                case .openSourceLicenses(let route):
                    return route.trackSegment
                }
            }

            @ViewBuilder
            var destinationView: some View {
                switch self {
                case .main:
                    AboutView()
                case .openSourceLicenses(let route):
                    route.destinationView
                }
            }

            enum OpenSourceLicensesRoute: Hashable {
                case main
                case detail(OpenSourceLicense)

                var trackSegment: String {
                    switch self {
                    case .main:
                        return "OpenSourceLicenses"
                    case .detail:
                        return "OpenSourceLicenseDetail"
                    }
                }

                @ViewBuilder
                var destinationView: some View {
                    switch self {
                    case .main:
                        OpenSourceLicensesView()
                    case .detail(let license):
                        OpenSourceLicenseDetailView(license: license)
                    }
                }
            }
        }
    }
}

enum AppTabItem: Hashable {
    case overview
    case features
    case profile
    case feature(FeatureTabID)

    var trackSegment: String {
        switch self {
        case .overview:
            return "Overview"
        case .features:
            return "Features"
        case .profile:
            return "Profile"
        case .feature(let feature):
            return feature.trackSegment
        }
    }
}
