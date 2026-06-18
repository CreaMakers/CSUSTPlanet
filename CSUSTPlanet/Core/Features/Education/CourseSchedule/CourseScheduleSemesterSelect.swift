//
//  CourseScheduleSemesterSelect.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/6/18.
//

import SwiftUI

private struct CourseScheduleSemesterSelectContent: View {
    @Binding var selectedSemester: String?
    let availableSemesters: [String]
    let isLoading: Bool

    @Binding var errorToast: ToastState

    let onRefresh: () async -> Void
    let onComplete: () async -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("学期选择") {
                    Picker("学期", selection: $selectedSemester) {
                        Text("默认学期").tag(nil as String?)
                        ForEach(availableSemesters, id: \.self) { semester in
                            Text(semester).tag(semester as String?)
                        }
                    }
                    #if os(iOS)
                    .pickerStyle(.wheel)
                    #elseif os(macOS)
                    .pickerStyle(.menu)
                    #endif
                }
                HStack {
                    Button(asyncAction: onRefresh) {
                        Text("刷新学期列表")
                    }
                    .disabled(isLoading)
                    if isLoading {
                        Spacer()
                        ProgressView().smallControlSizeOnMac()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("完成") {
                        dismiss()
                        await onComplete()
                    }
                    .disabled(isLoading)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("学期选择")
            .inlineToolbarTitle()
            .errorToast($errorToast)
        }
    }
}

#Preview("CourseScheduleSemesterSelectContent") {
    @Previewable @State var availableSemesters: [String] = []
    @Previewable @State var isLoading = false

    CourseScheduleSemesterSelectContent(
        selectedSemester: .constant(nil),
        availableSemesters: availableSemesters,
        isLoading: isLoading,
        errorToast: .constant(.errorTitle),
        onRefresh: {
            isLoading = true
            defer { isLoading = false }

            try? await Task.sleep(for: .seconds(1))

            availableSemesters = ["2024-2025-1", "2024-2025-2"]
        },
        onComplete: {}
    )
}

struct CourseScheduleSemesterSelect: View {
    @State private var selectedSemester: String?
    @State private var availableSemesters: [String] = []
    @State private var isLoading: Bool = false

    @State private var errorToast: ToastState = .errorTitle

    let onComplete: (String?) async -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        CourseScheduleSemesterSelectContent(
            selectedSemester: $selectedSemester,
            availableSemesters: availableSemesters,
            isLoading: isLoading,
            errorToast: $errorToast,
            onRefresh: loadAvailableSemesters,
            onComplete: {
                await onComplete(selectedSemester)
            }
        )
        .task {
            await loadAvailableSemesters()
        }
    }

    private func loadAvailableSemesters() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            (availableSemesters, selectedSemester) = try await AuthManager.shared.withAuthRetry(system: .edu) {
                try await AuthManager.shared.eduHelper.courseService.getAvailableSemestersForCourseSchedule()
            }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}
