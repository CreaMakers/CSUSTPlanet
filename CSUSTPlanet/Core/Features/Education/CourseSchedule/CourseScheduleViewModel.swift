//
//  CourseScheduleViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/18.
//

import CSUSTKit
import Foundation
import SwiftData
import SwiftUI
import WidgetKit

@MainActor
class CourseScheduleViewModel: ObservableObject {
    @Published var data: Cached<CourseScheduleData>? = nil
    @Published var errorMessage: String = ""
    @Published var warningMessage: String = ""
    @Published var availableSemesters: [String] = []

    @Published var isLoading: Bool = false
    @Published var isShowingWarning: Bool = false
    @Published var isShowingError: Bool = false
    @Published var isSemestersLoading: Bool = false
    @Published var isShowingSemestersSheet: Bool = false

    // TabView显示的第几周
    @Published var currentWeek: Int = 1
    @Published var selectedSemester: String? = nil

    var courseColors: [String: Color] = [:]

    // 当日日期
    // #if DEBUG
    //     let today: Date = {
    //         let dateFormatter = DateFormatter()
    //         dateFormatter.dateFormat = "yyyy-MM-dd"
    //         // 调试时使用固定日期
    //         return dateFormatter.date(from: "2025-09-15")!
    //     }()
    // #else
    let today: Date = .now
    // #endif

    // 当前日期在第几周
    @Published var realCurrentWeek: Int? = nil

    var isLoaded = false

    init() {
        guard let data = MMKVHelper.shared.courseScheduleCache else { return }
        self.data = data
        updateSchedules(data.value.semesterStartDate, data.value.courses)
    }

    func task() {
        guard !isLoaded else { return }
        isLoaded = true
        loadAvailableSemesters()
        loadCourses()
    }

    func loadAvailableSemesters() {
        guard let eduHelper = AuthManager.shared.eduHelper else { return }
        isSemestersLoading = true
        Task {
            defer {
                isSemestersLoading = false
            }

            do {
                (availableSemesters, selectedSemester) = try await eduHelper.courseService.getAvailableSemestersForCourseSchedule()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    private func updateSchedules(_ semesterStartDate: Date, _ courses: [EduHelper.Course]) {
        self.realCurrentWeek = CourseScheduleUtil.getCurrentWeek(semesterStartDate: semesterStartDate, now: today)

        // 为每门课程分配颜色
        courseColors = ColorUtil.getCourseColors(courses)

        // 自动跳转到当前周
        if let week = realCurrentWeek {
            withAnimation {
                self.currentWeek = week
            }
        }
    }

    func loadCourses() {
        isLoading = true
        Task {
            defer {
                isLoading = false
            }

            if let eduHelper = AuthManager.shared.eduHelper {
                do {
                    let courses = try await eduHelper.courseService.getCourseSchedule(academicYearSemester: selectedSemester)
                    let semesterStartDate = try await eduHelper.semesterService.getSemesterStartDate(academicYearSemester: selectedSemester)
                    let data = Cached<CourseScheduleData>(cachedAt: .now, value: CourseScheduleData(semester: selectedSemester, semesterStartDate: semesterStartDate, courses: courses))
                    self.data = data
                    MMKVHelper.shared.courseScheduleCache = data
                    updateSchedules(semesterStartDate, courses)
                    WidgetCenter.shared.reloadTimelines(ofKind: "TodayCoursesWidget")
                    WidgetCenter.shared.reloadTimelines(ofKind: "WeeklyCoursesWidget")
                } catch {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            } else {
                guard let data = MMKVHelper.shared.courseScheduleCache else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.warningMessage = "请先登录教务系统后再查询数据"
                        self.isShowingWarning = true
                    }
                    return
                }
                self.data = data
                updateSchedules(data.value.semesterStartDate, data.value.courses)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.warningMessage = String(format: "教务系统未登录，\n已加载上次查询数据（%@）", DateUtil.relativeTimeString(for: data.cachedAt))
                    self.isShowingWarning = true
                }
            }
        }
    }

    func goToCurrentWeek() {
        if let realWeek = realCurrentWeek, realWeek > 0 && realWeek <= CourseScheduleUtil.weekCount {
            withAnimation {
                self.currentWeek = realWeek
            }
        } else {
            withAnimation {
                self.currentWeek = 1
            }
        }
    }
}
