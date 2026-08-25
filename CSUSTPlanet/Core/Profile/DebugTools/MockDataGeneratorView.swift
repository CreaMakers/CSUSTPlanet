//
//  MockDataGeneratorView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/27.
//

#if DEBUG
import SwiftUI

struct MockDataGeneratorView: View {
    @State private var viewModel = MockDataGeneratorViewModel()

    var body: some View {
        Form {
            Section {
                Button("清空待提交作业数据（nil）") {
                    viewModel.clearTodoAssignmentsCache()
                }

                Button("清空待提交作业数据（空数组）") {
                    viewModel.setEmptyTodoAssignmentsCache()
                }

                Button("生成两个模拟待提交作业") {
                    viewModel.generateMockTodoAssignments()
                }
            } header: {
                Text("待提交作业")
            } footer: {
                Text(viewModel.todoAssignmentsCacheDescription)
            }

            Section {
                Button("清空考试安排数据（nil）") {
                    viewModel.clearExamSchedulesCache()
                }

                Button("清空考试安排数据（空数组）") {
                    viewModel.setEmptyExamSchedulesCache()
                }

                Button("生成 5 条模拟考试安排") {
                    viewModel.generateMockExamSchedules()
                }
            } header: {
                Text("考试安排")
            } footer: {
                Text(viewModel.examSchedulesCacheDescription)
            }

            Section {
                Button("清空课表数据（nil）") {
                    viewModel.clearCourseScheduleCache()
                }

                Button("清空课表数据（空课程）") {
                    viewModel.setEmptyCourseScheduleCache()
                }

                Button("生成今日满课模拟课表") {
                    viewModel.generateTodayFilledCourseSchedule()
                }

                Button("生成有冲突的模拟课表") {
                    viewModel.generateConflictedCourseSchedule()
                }
            } header: {
                Text("课表")
            } footer: {
                Text(viewModel.courseScheduleCacheDescription)
            }

            Section {
                Button("生成模拟电量") {
                    viewModel.generateMockElectricity()
                }
            } header: {
                Text("宿舍电量")
            } footer: {
                Text(viewModel.electricityCacheDescription)
            }
        }
        .formStyle(.grouped)
        .errorToast($viewModel.errorToast)
        .navigationTitle("模拟数据生成")
        .onAppear {
            viewModel.onAppear()
        }
    }
}
#endif
