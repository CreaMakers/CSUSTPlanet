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

    let colSpacing: CGFloat = 4  // 列间距
    let rowSpacing: CGFloat = 4  // 行间距
    let timeColWidth: CGFloat = 35  // 左侧时间列宽度
    let headerHeight: CGFloat = 50  // 顶部日期行的高度
    let sectionHeight: CGFloat = 70  // 单个课程格子的高度

    init() {
        loadDataFromLocal()
    }

    func loadAvailableSemesters() {
        isSemestersLoading = true
        Task {
            defer {
                isSemestersLoading = false
            }

            do {
                (availableSemesters, selectedSemester) = try await AuthManager.shared.eduHelper?.courseService.getAvailableSemestersForCourseSchedule() ?? ([], nil)
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    private func saveDataToLocal(_ data: Cached<CourseScheduleData>) {
        MMKVManager.shared.courseScheduleCache = data
        MMKVManager.shared.sync()
    }

    private func loadDataFromLocal(_ prompt: String? = nil) {
        guard let data = MMKVManager.shared.courseScheduleCache else { return }
        self.data = data
        updateSchedules(data.value.semesterStartDate, data.value.courses)

        if let prompt = prompt {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.warningMessage = String(format: prompt, DateHelper.relativeTimeString(for: data.cachedAt))
                self.isShowingWarning = true
            }
        }
    }

    private func updateSchedules(_ semesterStartDate: Date, _ courses: [EduHelper.Course]) {
        self.realCurrentWeek = CourseScheduleHelper.calculateCurrentWeek(semesterStartDate: semesterStartDate, now: today)

        // 为每门课程分配颜色
        courseColors = [:]
        var colorIndex = 0
        for course in courses.sorted(by: { $0.courseName < $1.courseName }) {
            if courseColors[course.courseName] == nil {
                courseColors[course.courseName] = ColorHelper.courseColors[colorIndex % ColorHelper.courseColors.count]
                colorIndex += 1
            }
        }

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
                    saveDataToLocal(data)
                    updateSchedules(semesterStartDate, courses)
                    WidgetCenter.shared.reloadTimelines(ofKind: "TodayCoursesWidget")
                    WidgetCenter.shared.reloadTimelines(ofKind: "WeeklyCoursesWidget")
                } catch {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            } else {
                loadDataFromLocal("教务系统未登录，已加载上次查询数据（%@）")
            }
        }
    }

    func goToCurrentWeek() {
        if let realWeek = realCurrentWeek, realWeek > 0 && realWeek <= CourseScheduleHelper.weekCount {
            withAnimation {
                self.currentWeek = realWeek
            }
        } else {
            withAnimation {
                self.currentWeek = 1
            }
        }
    }

    // 计算课程卡片的高度
    func calculateHeight(for session: EduHelper.ScheduleSession) -> CGFloat {
        let sections = CGFloat(session.endSection - session.startSection + 1)
        return sections * sectionHeight + (sections - 1) * rowSpacing
    }

    // 计算课程卡片的 Y 轴偏移
    func calculateYOffset(for session: EduHelper.ScheduleSession) -> CGFloat {
        let y = CGFloat(session.startSection - 1)
        return y * sectionHeight + y * rowSpacing
    }

    // 计算课程卡片的 X 轴偏移
    func calculateXOffset(for day: EduHelper.DayOfWeek, columnWidth: CGFloat) -> CGFloat {
        let x = CGFloat(day.rawValue)
        return timeColWidth + colSpacing + (x * columnWidth) + (x * colSpacing)
    }
}
