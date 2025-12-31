//
//  CourseSemesterView.swift
//  CSUSTPlanet
//
//  Created by liuzeyun on 2025/9/8.
//

import SwiftUI

struct CourseSemesterView: View {
    @EnvironmentObject var viewModel: CourseScheduleViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("学期选择") {
                    Picker("学期", selection: $viewModel.selectedSemester) {
                        Text("默认学期").tag(nil as String?)
                        ForEach(viewModel.availableSemesters, id: \.self) { semester in
                            Text(semester).tag(semester as String?)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                HStack {
                    Button(action: viewModel.loadAvailableSemesters) {
                        Text("刷新学期列表")
                    }
                    if viewModel.isSemestersLoading {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("完成") {
                        viewModel.loadCourses()
                        viewModel.isShowingSemestersSheet = false
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        viewModel.isShowingSemestersSheet = false
                    }
                }
            }
            .navigationTitle("学期选择")
            .navigationBarTitleDisplayMode(.inline)
            .trackView("CourseSemester")
        }
    }
}

#Preview {
    CourseSemesterView()
}
