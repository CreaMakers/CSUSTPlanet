//
//  TodoAssignmentsCoursePageScene.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/20.
//

import SwiftUI

#if os(macOS)
struct TodoAssignmentsCoursePageScene: Scene {
    static let windowID = "todo-assignments.course-page"

    var body: some Scene {
        WindowGroup("课程页面", id: Self.windowID, for: String.self) { $courseID in
            NavigationStack {
                if let courseID {
                    TodoAssignmentsCoursePage(courseID: courseID)
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
