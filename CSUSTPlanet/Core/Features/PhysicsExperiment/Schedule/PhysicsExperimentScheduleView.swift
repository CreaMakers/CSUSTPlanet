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
        Group {
            if viewModel.data?.value.isEmpty ?? true {
                emptyStateView
            } else {
                List {
                    if let data = viewModel.data {
                        ForEach(data.value, id: \.id) { course in
                            ExperimentCardView(course: course)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(.plain)
                .background(Color(uiColor: .systemGroupedBackground))
            }
        }
        .navigationTitle("大物实验安排")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { isLoginPresented = true }) {
                    Text("登录")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Button(action: viewModel.loadSchedules) {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
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
        .onChange(of: isLoginPresented) { _, newValue in
            if !newValue { viewModel.loadSchedules() }
        }
        .task {
            guard !viewModel.isLoaded else { return }
            viewModel.isLoaded = true
            viewModel.loadSchedules()
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "暂无实验安排",
            systemImage: "flask",
            description: Text("没有找到任何大物实验安排信息")
        )
    }
}

private struct ExperimentCardView: View {
    let course: PhysicsExperimentHelper.Course

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Text(course.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)

                    Spacer()

                    Text("批次 \(course.batch)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(Capsule())
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text(formatTime(course: course))
                            .fontWeight(.medium)
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundStyle(.blue)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.blue)

                    Label {
                        Text(course.location)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(.red)
                    }
                    .font(.subheadline)
                }

                Divider()
                    .overlay(.secondary.opacity(0.2))

                HStack {
                    Label(course.teacher, systemImage: "person.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Label("\(course.classHours) 课时", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
        }
    }

    private func formatTime(course: PhysicsExperimentHelper.Course) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: course.startTime)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let startStr = timeFormatter.string(from: course.startTime)
        let endStr = timeFormatter.string(from: course.endTime)

        return "\(dateStr) 周\(course.dayOfWeek.stringValue) \(startStr)-\(endStr)"
    }
}

#Preview {
    NavigationStack {
        PhysicsExperimentScheduleView()
    }
}
