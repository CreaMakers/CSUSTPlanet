//
//  CourseScheduleCalendarSettingsView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/3/9.
//

import SwiftUI

struct CourseScheduleCalendarSettingsView: View {
    @Bindable var viewModel: CourseScheduleViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("开启提醒", isOn: $viewModel.isFirstReminderEnabled.withAnimation())
                    if viewModel.isFirstReminderEnabled {
                        reminderPicker(title: "提醒时间", selection: $viewModel.firstReminderOffset)
                    }
                } header: {
                    Text("提醒")
                } footer: {
                    Text("作为你的主要上课提醒。可以设置为你需要出门通勤或做课前准备的时间。")
                }

                Section {
                    Toggle("开启额外提醒", isOn: $viewModel.isSecondReminderEnabled.withAnimation())
                    if viewModel.isSecondReminderEnabled {
                        reminderPicker(title: "额外提醒时间", selection: $viewModel.secondReminderOffset)
                    }
                } header: {
                    Text("额外提醒")
                } footer: {
                    Text("你也可以设置两个不同的提醒时间，一个用于预留充足的准备时间，另一个用于临近上课时的最终提醒。")
                }

                Section {
                    Toggle("限制导出范围", isOn: $viewModel.isExportScopeLimited.withAnimation())
                    if viewModel.isExportScopeLimited {
                        Picker("导出范围", selection: $viewModel.exportScope) {
                            ForEach(CalendarExportScope.allCases) { scope in
                                Text(scope.title).tag(scope)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("导出范围")
                } footer: {
                    Text("每次打开课表页面时会自动将课程导出到系统日历。默认导出本学期所有课程，开启后可限制仅导出未来几周的课程。")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("添加课表到系统日历")
            .inlineToolbarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        viewModel.isCalendarSettingsSheetPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        viewModel.isCalendarSettingsSheetPresented = false
                        await viewModel.addToCalendar()
                    }
                }
            }
        }
    }

    @ViewBuilder
    func reminderPicker(title: String, selection: Binding<CalendarReminderOffset>) -> some View {
        Picker(title, selection: selection) {
            ForEach(CalendarReminderOffset.allCases) { offset in
                Text(offset.title).tag(offset)
            }
        }
        .pickerStyle(.menu)
    }
}
