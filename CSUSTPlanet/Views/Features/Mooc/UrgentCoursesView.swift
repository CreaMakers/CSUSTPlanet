//
//  UrgentCoursesView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import AlertToast
import CSUSTKit
import SwiftUI

struct UrgentCoursesView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var viewModel = UrgentCoursesViewModel()

    // MARK: - Course Card

    private func courseCard(course: UrgentCourseData.Course) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(course.name)
                .font(.headline)
                .lineLimit(2)

            HStack(spacing: 8) {
                Image(systemName: "number")
                    .foregroundColor(.blue)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text("课程ID")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(course.id)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "book.closed")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
                .padding(.bottom, 8)

            Text("暂无待提交作业")
                .font(.headline)

            Text("当前没有需要提交作业的课程")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if let data = viewModel.data, !data.courses.isEmpty {
                List {
                    ForEach(data.courses, id: \.id) { course in
                        courseCard(course: course)
                    }
                }
                .listStyle(.insetGrouped)
            } else {
                emptyState
                    .background(Color(.systemGroupedBackground))
            }
        }
        .toast(isPresenting: $viewModel.isShowingError) {
            AlertToast(type: .error(.red), title: "错误", subTitle: viewModel.errorMessage)
        }
        .toast(isPresenting: $viewModel.isShowingWarning) {
            AlertToast(displayMode: .banner(.slide), type: .systemImage("exclamationmark.triangle", .yellow), title: "警告", subTitle: viewModel.warningMessage)
        }
        .task { viewModel.loadUrgentCourses(authManager.moocHelper) }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.9, anchor: .center)
                } else {
                    Button(action: { viewModel.loadUrgentCourses(authManager.moocHelper) }) {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .navigationTitle("待提交作业")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    UrgentCoursesView()
}
