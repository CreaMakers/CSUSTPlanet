//
//  PhysicsExperimentScheduleView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/11/3.
//

import AlertToast
import CSUSTKit
import SwiftUI

struct PhysicsExperimentScheduleView: View {
    @StateObject var viewModel = PhysicsExperimentScheduleViewModel()
    @State private var isLoginPresented: Bool = false

    var body: some View {
        Form {
            if viewModel.data?.value.isEmpty ?? true {
                emptyStateSection
            } else {
                scheduleListSection
            }
        }
        .sheet(isPresented: $isLoginPresented) {
            PhysicsExperimentLoginView(isPresented: $isLoginPresented)
        }
        .toast(isPresenting: $viewModel.isShowingError) {
            AlertToast(type: .error(.red), title: "错误", subTitle: viewModel.errorMessage)
        }
        .toast(isPresenting: $viewModel.isShowingWarning) {
            AlertToast(displayMode: .banner(.slide), type: .systemImage("exclamationmark.triangle", .yellow), title: "警告", subTitle: viewModel.warningMessage)
        }
        .task {
            guard !viewModel.isLoaded else { return }
            viewModel.isLoaded = true
            viewModel.loadSchedules()
        }
        .navigationTitle("大物实验安排")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    isLoginPresented = true
                }) {
                    Text("登录")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.9, anchor: .center)
                } else {
                    Button(action: viewModel.loadSchedules) {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }

    // MARK: - Form Sections

    private var emptyStateSection: some View {
        Section {
            VStack(spacing: 8) {
                Image(systemName: "flask")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)

                Text("暂无实验安排")
                    .font(.headline)

                Text("没有找到任何大物实验安排信息")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }

    private var scheduleListSection: some View {
        Section {
            if let data = viewModel.data {
                ForEach(data.value, id: \.id) { course in
                    scheduleCard(course: course)
                }
            }
        }
    }

    private func scheduleCard(course: PhysicsExperimentHelper.Course) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 项目名称
            Text(course.name)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(2)

            // 批次
            HStack(spacing: 4) {
                Image(systemName: "number")
                    .foregroundStyle(.blue)
                    .imageScale(.small)
                Text("批次: \(course.batch)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            // 教师和地点
            HStack(spacing: 12) {
                infoItem(icon: "person.fill", color: .purple, text: course.teacher)
                infoItem(icon: "mappin.circle.fill", color: .red, text: course.location)
            }

            // 时间信息 - 在一行显示
            HStack(spacing: 4) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(.green)
                    .imageScale(.small)
                Text(formatFullDateTime(course: course))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
    }

    private func infoItem(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .imageScale(.small)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func formatFullDateTime(course: PhysicsExperimentHelper.Course) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.string(from: course.startTime)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let startTime = timeFormatter.string(from: course.startTime)
        let endTime = timeFormatter.string(from: course.endTime)

        return "\(date) 周\(course.dayOfWeek.stringValue) \(startTime)-\(endTime) (\(course.classHours)课时)"
    }
}

#Preview {
    PhysicsExperimentScheduleView()
}
