//
//  CourseInfoSection.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/21.
//

import CSUSTKit
import SwiftUI

struct CourseInfoSection: View {
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #elseif os(iOS)
    @State private var isCoursePagePresented = false
    #endif

    let course: MoocHelper.Course

    var body: some View {
        CustomGroupBox {
            VStack(alignment: .leading, spacing: 12) {
                CourseInfoRow(label: "课程名称", value: course.name)
                if let number = course.number {
                    CourseInfoRow(label: "课程编号", value: number)
                }
                if let department = course.department {
                    CourseInfoRow(label: "开课院系", value: department)
                }
                if let teacher = course.teacher {
                    CourseInfoRow(label: "授课教师", value: teacher)
                }

                HStack {
                    Spacer()

                    Button {
                        openCoursePage()
                    } label: {
                        Label("前往课程网页", systemImage: "safari")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        #if os(iOS)
        .sheet(isPresented: $isCoursePagePresented) {
            NavigationStack {
                AssignmentsCoursePage(courseID: course.id)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("关闭") {
                            isCoursePagePresented = false
                        }
                    }
                }
            }
        }
        #endif
    }

    private func openCoursePage() {
        #if os(macOS)
        openWindow(id: AssignmentsCoursePageScene.windowID, value: course.id)
        #elseif os(iOS)
        isCoursePagePresented = true
        #endif
    }
}

private struct CourseInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.callout)

            Spacer()

            Text(value)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview("CourseInfoSection") {
    CustomScrollView {
        CourseInfoSection(course: MoocCoursesPreviewData.mobileDevelopmentCourse)
            .padding()
    }
}
