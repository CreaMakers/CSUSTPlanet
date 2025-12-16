//
//  CourseDetailViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/8/23.
//

import CSUSTKit
import Foundation

@MainActor
class CourseDetailViewModel: ObservableObject {
    @Published var homeworks: [MoocHelper.Homework] = []
    @Published var tests: [MoocHelper.Test] = []
    @Published var errorMessage = ""

    @Published var isShowingSuccess = false
    @Published var isShowingError = false
    @Published var isHomeworksLoading = false
    @Published var isTestsLoading = false

    @Published var isShowingRemindersSettings = false

    private var course: MoocHelper.Course
    @Published var isSimplified = false

    var courseInfo: MoocHelper.Course {
        return course
    }

    init(course: MoocHelper.Course) {
        self.course = course
        self.isSimplified = false
    }

    init(id: String, name: String) {
        self.course = MoocHelper.Course(id: id, number: "", name: name, department: "", teacher: "")
        self.isSimplified = true
    }

    func loadHomeworks() {
        isHomeworksLoading = true
        Task {
            defer {
                isHomeworksLoading = false
            }

            if let moocHelper = AuthManager.shared.moocHelper {
                do {
                    homeworks = try await moocHelper.getCourseHomeworks(courseId: course.id)
                } catch {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            } else {
                errorMessage = "请先等待网络课程中心登录完成后再重试"
                isShowingError = true
            }
        }
    }

    func loadTests() {
        isTestsLoading = true
        Task {
            defer {
                isTestsLoading = false
            }

            if let moocHelper = AuthManager.shared.moocHelper {
                do {
                    tests = try await moocHelper.getCourseTests(courseId: course.id)
                } catch {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            } else {
                errorMessage = "请先等待网络课程中心登录完成后再重试"
                isShowingError = true
            }
        }
    }

    lazy var dateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return dateFormatter
    }()

    func addHomeworksToReminders(_ alertHourOffset: Int, _ alertMinuteOffset: Int) {
        guard !homeworks.isEmpty else {
            errorMessage = "当前没有可添加的作业"
            isShowingError = true
            return
        }

        Task {
            do {
                let calendar = try await CalendarHelper.getOrCreateReminderCalendar(named: "长理星球 - 作业")
                for homework in homeworks {
                    guard homework.canSubmit else { continue }
                    let dueDate = homework.deadline
                    let alarmOffset = TimeInterval(-(alertHourOffset * 3600 + alertMinuteOffset * 60))
                    let dueDateWithAlarm = dueDate.addingTimeInterval(alarmOffset)
                    try await CalendarHelper.addReminder(
                        calendar: calendar,
                        title: homework.title,
                        dueDate: dueDateWithAlarm,
                        notes: "截止提交时间：\(dateFormatter.string(from: homework.deadline))\n课程老师：\(homework.publisher)"
                    )
                }
                isShowingSuccess = true
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }
}
