//
//  AvailableClassroomView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/1/8.
//

import AlertToast
import CSUSTKit
import SwiftUI

struct AvailableClassroomView: View {
    @StateObject var viewModel = AvailableClassroomViewModel()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Filter Section
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.blue)
                            Text("查询条件")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.bottom, 4)

                        // Campus Picker
                        LabeledContent {
                            Picker("校区", selection: $viewModel.selectedCampus) {
                                Text("金盆岭校区").tag(CampusCardHelper.Campus.jinpenling)
                                Text("云塘校区").tag(CampusCardHelper.Campus.yuntang)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                        } label: {
                            Label("校区", systemImage: "building.2")
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        // Week Picker
                        LabeledContent {
                            Picker("周数", selection: $viewModel.selectedWeek) {
                                ForEach(1...20, id: \.self) { week in
                                    Text("第 \(week) 周").tag(week)
                                }
                            }
                            .tint(.secondary)
                        } label: {
                            Label("周数", systemImage: "calendar")
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        // Day Picker
                        LabeledContent {
                            Picker("星期", selection: $viewModel.selectedDayOfWeek) {
                                ForEach(EduHelper.DayOfWeek.allCases, id: \.self) { dayOfWeek in
                                    Text(dayOfWeekToString(dayOfWeek)).tag(dayOfWeek)
                                }
                            }
                            .tint(.secondary)
                        } label: {
                            Label("星期", systemImage: "sun.max")
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        // Section Picker
                        LabeledContent {
                            Picker("节次", selection: $viewModel.selectedSection) {
                                ForEach(1...5, id: \.self) { section in
                                    Text("第\(section)大节 (\(section * 2 - 1)-\(section * 2))").tag(section)
                                }
                            }
                            .tint(.secondary)
                        } label: {
                            Label("节次", systemImage: "clock")
                                .foregroundColor(.secondary)
                        }

                        // Query Button
                        Button(action: viewModel.queryAvailableClassrooms) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .padding(.trailing, 5)
                                } else {
                                    Image(systemName: "magnifyingglass")
                                }
                                Text(viewModel.isLoading ? "查询中..." : "查询空教室")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                        .padding(.top, 8)
                        .disabled(viewModel.isLoading)
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

                    // MARK: - Results Section
                    if let availableClassrooms = viewModel.filteredAvailableClassrooms {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("查询结果", systemImage: "list.bullet.rectangle.portrait")
                                    .font(.headline)
                                Spacer()
                                Text("共 \(availableClassrooms.count) 间")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 4)

                            if availableClassrooms.isEmpty {
                                if viewModel.searchText.isEmpty {
                                    emptyStateView
                                } else {
                                    ContentUnavailableView.search(text: viewModel.searchText)
                                }
                            } else {
                                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible(), spacing: 12),
                                        GridItem(.flexible(), spacing: 12),
                                    ], spacing: 12
                                ) {
                                    ForEach(availableClassrooms, id: \.self) { classroom in
                                        Text(classroom)
                                            .font(.callout)
                                            .fontWeight(.medium)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                    } else {
                        // Initial State Hint
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("点击上方按钮开始查询")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("空教室查询")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, prompt: "搜索查询结果")
        .toast(isPresenting: $viewModel.isShowingError) {
            AlertToast(type: .error(.red), title: "错误", subTitle: viewModel.errorMessage)
        }
        .toast(isPresenting: $viewModel.isShowingWarning) {
            AlertToast(displayMode: .banner(.slide), type: .systemImage("exclamationmark.triangle", .yellow), title: "警告", subTitle: viewModel.warningMessage)
        }
        .trackView("AvailableClassroom")
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "deskclock")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("该时间段无空闲教室")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func dayOfWeekToString(_ dayOfWeek: EduHelper.DayOfWeek) -> String {
        switch dayOfWeek {
        case .monday: return "星期一"
        case .tuesday: return "星期二"
        case .wednesday: return "星期三"
        case .thursday: return "星期四"
        case .friday: return "星期五"
        case .saturday: return "星期六"
        case .sunday: return "星期日"
        }
    }
}
