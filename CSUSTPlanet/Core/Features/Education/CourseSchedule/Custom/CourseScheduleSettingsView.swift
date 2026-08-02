//
//  CourseScheduleSettingsView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/8/2.
//

import Combine
import Foundation
import GRDB
import SwiftUI

// MARK: - Content

struct CourseScheduleSettingsContent: View {
    let schedules: [CustomCourseScheduleGRDB]
    let currentScheduleID: String?
    let defaultScheduleStartDate: Date?
    let hasSchoolSchedule: Bool

    let onActivateDefault: () -> Void

    @State private var createModeIsImport: Bool?

    var body: some View {
        List {
            Section {
                Button {
                    onActivateDefault()
                } label: {
                    scheduleRow(
                        title: "默认课表",
                        subtitle: defaultScheduleStartDate.map { CourseScheduleUtil.dateFormatter.string(from: $0) } ?? CourseScheduleUtil.emptyCourseScheduleText,
                        isCurrent: currentScheduleID == nil
                    )
                }
                .buttonStyle(.plain)
            } footer: {
                Text("默认课表跟随学校课表自动刷新")
            }

            Section("自定义课表") {
                if schedules.isEmpty {
                    Text("暂无自定义课表，点击右上角 + 创建")
                        .foregroundStyle(.secondary)
                }
                ForEach(schedules) { schedule in
                    NavigationLink(value: AppRoute.features(.education(.courseScheduleEdit(schedule)))) {
                        scheduleRow(
                            title: schedule.name,
                            subtitle: CourseScheduleUtil.dateFormatter.string(from: schedule.semesterStartDate),
                            isCurrent: currentScheduleID == schedule.id
                        )
                    }
                }
            }
        }
        .navigationTitle("课表设置")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        createModeIsImport = false
                    } label: {
                        Label("从空白创建", systemImage: "square.dashed")
                    }

                    Button {
                        createModeIsImport = true
                    } label: {
                        Label("从学校课表导入", systemImage: "tray.and.arrow.down")
                    }
                    .disabled(!hasSchoolSchedule)
                } label: {
                    Label("新建课表", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: Binding(get: { createModeIsImport != nil }, set: { if !$0 { createModeIsImport = nil } })) {
            CourseScheduleCreateSheet(
                isImportFromSchool: createModeIsImport ?? false,
                defaultName: "我的课表 \(schedules.count + 1)",
                defaultStartDate: defaultScheduleStartDate
            )
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Helpers

    private func scheduleRow(title: String, subtitle: String, isCurrent: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isCurrent {
                Image(systemName: "checkmark")
                    .fontWeight(.semibold)
                    .foregroundStyle(.tint)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - 业务容器

struct CourseScheduleSettingsView: View {
    @State private var schedules: [CustomCourseScheduleGRDB] = []
    @State private var currentScheduleID: String?
    @State private var schoolCache: Cached<CourseScheduleData>?

    @State private var errorToast: ToastState = .errorTitle
    @State private var successToast: ToastState = .successTitle

    @State private var listObserver: (any DatabaseCancellable)?
    @State private var ipcCancellable: AnyCancellable?
    @State private var cancellables: Set<AnyCancellable> = []

    @State private var isInitial: Bool = true

    var body: some View {
        CourseScheduleSettingsContent(
            schedules: schedules,
            currentScheduleID: currentScheduleID,
            defaultScheduleStartDate: schoolCache?.value.semesterStartDate,
            hasSchoolSchedule: schoolCache != nil,
            onActivateDefault: activateDefaultSchedule
        )
        .task {
            await loadInitial()
        }
        .errorToast($errorToast)
        .successToast($successToast)
    }

    // MARK: - 切换当前课表

    private func activateDefaultSchedule() {
        guard currentScheduleID != nil else { return }
        MMKVHelper.CourseSchedule.currentScheduleID = nil
        successToast.show(message: "已切换到默认课表")
    }

    // MARK: - 观察

    private func loadInitial() async {
        guard isInitial else { return }
        isInitial = false
        setupMMKVObservations()
        setupIPCObservationIfNeeded()
        restartListObservation()
    }

    private func setupMMKVObservations() {
        guard cancellables.isEmpty else { return }

        MMKVHelper.CourseSchedule.$cache
            .receive(on: RunLoop.main)
            .sink { cache in
                schoolCache = cache
            }
            .store(in: &cancellables)

        MMKVHelper.CourseSchedule.$currentScheduleID
            .receive(on: RunLoop.main)
            .sink { scheduleID in
                currentScheduleID = scheduleID
            }
            .store(in: &cancellables)
    }

    private func setupIPCObservationIfNeeded() {
        guard ipcCancellable == nil else { return }

        ipcCancellable = GRDBIPCNotifier.shared.dbChangedSubject
            .receive(on: DispatchQueue.main)
            .sink { _ in
                restartListObservation()
            }
    }

    private func restartListObservation() {
        listObserver?.cancel()
        guard let pool = DatabaseManager.shared.pool else { return }

        let observation = ValueObservation.tracking { db in
            try CustomCourseScheduleGRDB.fetchAll(db)
        }
        .map { schedules in
            schedules.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }

        listObserver = observation.start(
            in: pool,
            scheduling: .immediate,
            onError: { error in
                Task { @MainActor in
                    errorToast.show(message: error.localizedDescription)
                }
            },
            onChange: { schedules in
                Task { @MainActor in
                    self.schedules = schedules
                }
            }
        )
    }
}

#Preview("CourseScheduleSettingsContent") {
    NavigationStack {
        CourseScheduleSettingsContent(
            schedules: [
                CustomCourseScheduleGRDB(
                    id: "1",
                    name: "我的课表 1",
                    semesterStartDate: .now,
                    weekCount: 20,
                    remarks: "",
                    createdAt: .now
                ),
                CustomCourseScheduleGRDB(
                    id: "2",
                    name: "考研冲刺",
                    semesterStartDate: .now,
                    weekCount: 20,
                    remarks: "",
                    createdAt: .now
                ),
            ],
            currentScheduleID: "2",
            defaultScheduleStartDate: .now,
            hasSchoolSchedule: true,
            onActivateDefault: {}
        )
    }
}
