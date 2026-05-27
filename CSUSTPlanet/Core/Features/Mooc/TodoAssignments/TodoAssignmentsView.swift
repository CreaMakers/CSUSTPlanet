//
//  TodoAssignmentsView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/20.
//

import CSUSTKit
import SwiftUI

struct TodoAssignmentsCoursePageView: View {
    let courseID: String
    @State private var webViewController = WebViewController()

    var originalURL: URL? { URL(string: "http://pt.csust.edu.cn/meol/jpk/course/layout/newpage/index.jsp?courseId=\(courseID)") }
    var vpnURL: URL? {
        if let originalURL {
            try? WebVPNHelper.encryptURL(originalURL)
        } else {
            nil
        }
    }

    var url: URL? {
        if MMKVHelper.GlobalManager.isWebVPNModeEnabled {
            vpnURL
        } else {
            originalURL
        }
    }

    var body: some View {
        Group {
            if let url {
                WebView(
                    url: url,
                    cookies: CookieHelper.shared.session.session.configuration.httpCookieStorage?.cookies,
                    controller: webViewController
                )
            } else {
                ContentUnavailableView("无法打开课程页面", systemImage: "exclamationmark.triangle", description: Text("课程链接无效"))
            }
        }
        .navigationTitle("课程页面")
        .inlineToolbarTitle()
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { webViewController.goBack() }) {
                    Label("上一页", systemImage: "chevron.left")
                }
                .disabled(!webViewController.canGoBack)

                Button(action: { webViewController.goForward() }) {
                    Label("下一页", systemImage: "chevron.right")
                }
                .disabled(!webViewController.canGoForward)
            }

            ToolbarItem(placement: .primaryAction) {
                Button(action: { webViewController.reload() }) {
                    if webViewController.isLoading {
                        ProgressView().smallControlSizeOnMac()
                    } else {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

#if os(macOS)
struct TodoAssignmentsCoursePageScene: Scene {
    static let windowID = "todo-assignments.course-page"

    var body: some Scene {
        WindowGroup("课程页面", id: Self.windowID, for: String.self) { $courseID in
            NavigationStack {
                if let courseID {
                    TodoAssignmentsCoursePageView(courseID: courseID)
                } else {
                    ContentUnavailableView("未选择课程", systemImage: "book.closed", description: Text("请从待提交作业页面重新打开课程页面"))
                }
            }
            .frame(minWidth: 960, minHeight: 540)
        }
        .defaultSize(width: 1280, height: 720)
        .windowResizability(.contentMinSize)
    }
}
#endif

struct TodoAssignmentsView: View {
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif

    @State private var viewModel = TodoAssignmentsViewModel()

    var body: some View {
        Group {
            Form {
                if let courseGroups = viewModel.todoAssignmentsData?.value, !courseGroups.isEmpty {
                    ForEach(courseGroups, id: \.course.id) { group in
                        Section {
                            DisclosureGroup(isExpanded: bindingForCourse(group.course.id)) {
                                let assignments = viewModel.displayedAssignments(for: group)
                                let isShowingAllAssignments = viewModel.isShowingAllAssignments(courseID: group.course.id)
                                let hasHiddenAssignments = assignments.count < group.assignments.count

                                ForEach(assignments.indices, id: \.self) { index in
                                    AssignmentInfoView(assignment: assignments[index])
                                }

                                if hasHiddenAssignments || isShowingAllAssignments {
                                    Button {
                                        withAnimation { viewModel.toggleShowAllAssignments(courseID: group.course.id) }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text(isShowingAllAssignments ? "仅未截止" : "查看全部")
                                            Image(systemName: isShowingAllAssignments ? "chevron.up" : "chevron.down")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.vertical, 6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            } label: {
                                HStack {
                                    Text(group.course.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .contentShape(.rect)
                                        .onTapGesture {
                                            withAnimation { viewModel.toggleExpanded(courseID: group.course.id) }
                                        }

                                    Spacer()

                                    Button {
                                        #if os(macOS)
                                        openWindow(id: TodoAssignmentsCoursePageScene.windowID, value: group.course.id)
                                        #else
                                        viewModel.selectedCourseID = group.course.id
                                        viewModel.isCoursePagePresented = true
                                        #endif
                                    } label: {
                                        Text("前往课程")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    ContentUnavailableView("暂无待提交作业", systemImage: "book.closed", description: Text("当前没有需要提交的作业"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .formStyle(.grouped)
        }
        #if os(iOS)
        .background(Color(PlatformColor.systemGroupedBackground))
        #endif
        .task { await viewModel.loadInitial() }
        .safeRefreshable { await viewModel.loadTodoAssignments() }
        .errorToast($viewModel.errorToast)
        .sheet(isPresented: $viewModel.isNotificationSettingsPresented) {
            TodoAssignmentsNotificationSettingsView(viewModel: viewModel)
        }
        #if os(iOS)
        .sheet(isPresented: $viewModel.isCoursePagePresented) {
            NavigationStack {
                if let courseID = viewModel.selectedCourseID {
                    TodoAssignmentsCoursePageView(courseID: courseID)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("关闭") {
                                viewModel.isCoursePagePresented = false
                            }
                        }
                    }
                }
            }
        }
        #endif
        .alert("通知权限被拒绝", isPresented: $viewModel.isNotificationDeniedAlertPresented) {
            Button(action: { viewModel.isNotificationDeniedAlertPresented = false }) {
                Text("取消")
            }
            Button(action: {
                NotificationManager.shared.openAppNotificationSettings()
                viewModel.isNotificationDeniedAlertPresented = false
            }) {
                Text("前往设置")
            }
        } message: {
            Text("需要开启通知权限以接收待提交作业提醒，请前往系统设置开启通知权限")
        }
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Button(action: { viewModel.isNotificationSettingsPresented = true }) {
                    Label("作业提醒设置", systemImage: "bell.badge")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(asyncAction: viewModel.loadTodoAssignments) {
                    if viewModel.isLoadingAssignments {
                        ProgressView().smallControlSizeOnMac()
                    } else {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(viewModel.isLoadingAssignments)
            }
        }
        .navigationTitle("待提交作业")
        .navigationSubtitleCompat("共\(viewModel.unexpiredAssignmentsCount)个未截止作业")
    }

    private func bindingForCourse(_ courseID: String) -> Binding<Bool> {
        Binding(
            get: { viewModel.isExpanded(courseID: courseID) },
            set: { viewModel.setExpanded($0, courseID: courseID) }
        )
        .withAnimation()
    }
}

struct AssignmentInfoView: View {
    let assignment: MoocHelper.Assignment

    private var deadlineStyle: RelativeDateStyle {
        RelativeDateStyle.assignment(
            deadline: assignment.deadline,
            isSubmitted: assignment.submitStatus
        )
    }

    @ViewBuilder
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(assignment.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                Spacer()

                if assignment.submitStatus {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                } else if assignment.canSubmit {
                    Image(systemName: "circle")
                        .foregroundColor(.orange)
                        .font(.caption)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            HStack {
                Text("发布人")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(assignment.publisher)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("开始时间")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(assignment.startTime, format: .dateTime.year().month().day().hour().minute())
                    .font(.caption)
                    .foregroundColor(.secondary)
                RelativeDateBadge(
                    text: assignment.startTime.formatted(.relative(presentation: .named, unitsStyle: .abbreviated)),
                    style: .secondary,
                    font: .caption2.bold(),
                    horizontalPadding: 6,
                    verticalPadding: 2
                )
            }

            HStack {
                Text("截止时间")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(assignment.deadline, format: .dateTime.year().month().day().hour().minute())
                    .font(.caption)
                    .foregroundColor(deadlineStyle.accentColor)
                RelativeDateBadge(
                    text: assignment.deadline.formatted(.relative(presentation: .named, unitsStyle: .abbreviated)),
                    style: deadlineStyle,
                    font: .caption2.bold(),
                    horizontalPadding: 6,
                    verticalPadding: 2
                )
            }
        }
        .padding(.vertical, 6)
    }
}
