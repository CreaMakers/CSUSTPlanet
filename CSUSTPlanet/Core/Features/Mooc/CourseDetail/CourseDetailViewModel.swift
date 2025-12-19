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
    @Published var assignments: [MoocHelper.Assignment] = []
    @Published var tests: [MoocHelper.Test] = []
    @Published var errorMessage = ""

    @Published var isShowingSuccess = false
    @Published var isShowingError = false
    @Published var isAssignmentsLoading = false
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

    func loadAssignments() {
        isAssignmentsLoading = true
        Task {
            defer {
                isAssignmentsLoading = false
            }

            if let moocHelper = AuthManager.shared.moocHelper {
                do {
                    assignments = try await moocHelper.getCourseAssignments(courseId: course.id)
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

    func addAssignmentsToReminders(_ alertHourOffset: Int, _ alertMinuteOffset: Int) {
        guard !assignments.isEmpty else {
            errorMessage = "当前没有可添加的作业"
            isShowingError = true
            return
        }

        Task {
            do {
                let calendar = try await CalendarUtil.getOrCreateReminderCalendar(named: "长理星球 - 作业")
                for assignment in assignments {
                    guard assignment.canSubmit else { continue }
                    let dueDate = assignment.deadline
                    let alarmOffset = TimeInterval(-(alertHourOffset * 3600 + alertMinuteOffset * 60))
                    let dueDateWithAlarm = dueDate.addingTimeInterval(alarmOffset)
                    try await CalendarUtil.addReminder(
                        calendar: calendar,
                        title: assignment.title,
                        dueDate: dueDateWithAlarm,
                        notes: "截止提交时间：\(dateFormatter.string(from: assignment.deadline))\n课程老师：\(assignment.publisher)"
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
