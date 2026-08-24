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
    @State var viewModel = AvailableClassroomViewModel()

    var body: some View {
        CustomScrollView {
            VStack(spacing: 20) {
                // MARK: - Filter Section
                CustomGroupBox {
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.accentColor)
                            Text("查询条件")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.bottom, 4)

                        // Campus Picker
                        filterRow(title: "校区", systemImage: "building.2") {
                            Picker("", selection: $viewModel.selectedCampus) {
                                Text("金盆岭校区").tag(CampusCardHelper.Campus.jinpenling)
                                Text("云塘校区").tag(CampusCardHelper.Campus.yuntang)
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                            .fixedSize()
                        }

                        Divider()

                        // Week Picker
                        filterRow(title: "周数", systemImage: "calendar") {
                            Picker("", selection: $viewModel.selectedWeek) {
                                ForEach(1...20, id: \.self) { week in
                                    Text("第 \(week) 周").tag(week)
                                }
                            }
                            .labelsHidden()
                            .tint(.secondary)
                            .fixedSize()
                        }

                        Divider()

                        // Day Picker
                        filterRow(title: "星期", systemImage: "sun.max") {
                            Picker("", selection: $viewModel.selectedDayOfWeek) {
                                ForEach(EduHelper.DayOfWeek.allCases, id: \.self) { dayOfWeek in
                                    Text(dayOfWeek.chineseLongString).tag(dayOfWeek)
                                }
                            }
                            .labelsHidden()
                            .tint(.secondary)
                            .fixedSize()
                        }

                        Divider()

                        // Section Picker
                        filterRow(title: "节次", systemImage: "clock") {
                            Picker("", selection: $viewModel.selectedSection) {
                                ForEach(1...5, id: \.self) { section in
                                    Text("第\(section)大节 (\(section * 2 - 1)-\(section * 2))").tag(section)
                                }
                            }
                            .labelsHidden()
                            .tint(.secondary)
                            .fixedSize()
                        }

                        // Query Button
                        Button(asyncAction: viewModel.queryAvailableClassrooms) {
                            HStack {
                                if viewModel.isLoadingClassrooms {
                                    ProgressView()
                                        .smallControlSizeOnMac()
                                        .tint(.white)
                                        .padding(.trailing, 5)
                                } else {
                                    Image(systemName: "magnifyingglass")
                                }
                                Text(viewModel.isLoadingClassrooms ? "查询中..." : "查询空教室")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(.capsule)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                        .disabled(viewModel.isLoadingClassrooms)
                    }
                }

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
                                ContentUnavailableView("该时间段无空闲教室", systemImage: "deskclock")
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                ContentUnavailableView.search(text: viewModel.searchText)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        } else {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12),
                                ], spacing: 12
                            ) {
                                ForEach(availableClassrooms, id: \.self) { classroom in
                                    CustomGroupBox {
                                        Text(classroom)
                                            .font(.callout)
                                            .fontWeight(.medium)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView("请点击上方按钮开始查询", systemImage: "magnifyingglass.circle")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding()
        }

        #if os(iOS)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索查询结果")
        #elseif os(macOS)
        .searchable(text: $viewModel.searchText, placement: .toolbar, prompt: "搜索查询结果")
        #endif
        .navigationTitle("空教室查询")
        .inlineToolbarTitle()
        .errorToast($viewModel.errorToast)
    }

    @ViewBuilder
    private func filterRow<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            Label(title, systemImage: systemImage)
                .foregroundColor(.secondary)

            Spacer()

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
