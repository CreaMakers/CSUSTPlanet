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
    let onActivateSchedule: (CustomCourseScheduleGRDB) -> Void
    let onDeleteSchedule: (CustomCourseScheduleGRDB) -> Void

    @State private var createModeIsImport: Bool?
    @State private var schedulePendingDelete: CustomCourseScheduleGRDB?

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
                    .contentShape(.rect)
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
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if currentScheduleID != schedule.id {
                            Button {
                                onActivateSchedule(schedule)
                            } label: {
                                Label("设为当前", systemImage: "checkmark.circle")
                            }
                            .tint(.blue)
                        }
                        Button(role: .destructive) {
                            schedulePendingDelete = schedule
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
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
        .alert(
            "删除课表",
            isPresented: Binding(get: { schedulePendingDelete != nil }, set: { if !$0 { schedulePendingDelete = nil } }),
            presenting: schedulePendingDelete
        ) { schedule in
            Button("删除", role: .destructive) {
                onDeleteSchedule(schedule)
            }
            Button("取消", role: .cancel) {}
        } message: { schedule in
            Text("确定要删除「\(schedule.name)」吗？删除后不可恢复")
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
            onActivateDefault: activateDefaultSchedule,
            onActivateSchedule: activateSchedule,
            onDeleteSchedule: deleteSchedule
        )
        .task {
            await loadInitial()
        }
        .errorToast($errorToast)
    }

    // MARK: - 切换当前课表

    private func activateDefaultSchedule() {
        guard currentScheduleID != nil else { return }
        MMKVHelper.CourseSchedule.currentScheduleID = nil
    }

    private func activateSchedule(_ schedule: CustomCourseScheduleGRDB) {
        MMKVHelper.CourseSchedule.currentScheduleID = schedule.id
    }

    // MARK: - 删除课表

    private func deleteSchedule(_ schedule: CustomCourseScheduleGRDB) {
        guard schedule.id != currentScheduleID else {
            errorToast.show(message: "此课表为当前选择课表，不能删除，请先切换到其他课表再删除")
            return
        }
        guard let pool = DatabaseManager.shared.pool else {
            errorToast.show(message: DatabaseManagerError.databaseUnavailable.localizedDescription)
            return
        }

        do {
            try pool.write { db in
                _ = try CustomCourseScheduleGRDB.deleteOne(db, key: schedule.id)
            }
        } catch {
            errorToast.show(message: "删除失败：\(error.localizedDescription)")
        }
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
            onActivateDefault: {},
            onActivateSchedule: { _ in },
            onDeleteSchedule: { _ in }
        )
    }
}
