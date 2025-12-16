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
    @State private var now = Date()

    var body: some View {
        Group {
            if viewModel.data?.value.isEmpty ?? true {
                emptyStateView
            } else {
                List {
                    if let data = viewModel.data {
                        ForEach(data.value, id: \.id) { course in
                            ExperimentCardView(course: course, now: now)
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
            now = Date()
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
    let now: Date

    private var isFinished: Bool {
        return now > course.endTime
    }

    private var daysUntil: Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        let courseDay = calendar.startOfDay(for: course.startTime)
        let components = calendar.dateComponents([.day], from: startOfDay, to: courseDay)
        return components.day ?? 0
    }

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
                        .foregroundStyle(isFinished ? .secondary : .primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            if isFinished {
                                Text("已结束")
                                    .font(.caption2.bold())
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.gray.opacity(0.15), in: Capsule())
                            } else {
                                if daysUntil == 0 {
                                    Text("今天")
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.red, in: Capsule())
                                } else if daysUntil == 1 {
                                    Text("明天")
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.orange, in: Capsule())
                                } else {
                                    Text("还有 \(daysUntil) 天")
                                        .font(.caption2.bold())
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.blue.opacity(0.1), in: Capsule())
                                }
                            }

                            Text("批次 \(course.batch)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(isFinished ? .gray : .orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(isFinished ? Color.gray.opacity(0.15) : Color.orange.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text(formatTime(course: course))
                            .fontWeight(.medium)
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundStyle(isFinished ? .gray : .blue)
                    }
                    .font(.subheadline)
                    .foregroundStyle(isFinished ? Color.secondary : Color.blue)

                    Label {
                        Text(course.location)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(isFinished ? .gray : .red)
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
        .opacity(isFinished ? 0.6 : 1.0)
        .saturation(isFinished ? 0.0 : 1.0)
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
