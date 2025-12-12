//
//  OverviewView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import SwiftUI

struct OverviewView: View {
    @StateObject var viewModel = OverviewViewModel()
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 头部欢迎语
                HomeHeaderView()
                    .padding(.horizontal)
                    .padding(.top, 10)

                // 今日课程
                HomeCourseCarousel(data: viewModel.courseScheduleData)

                // 核心数据网格 (成绩 + 电量)
                HStack(spacing: 16) {
                    HomeGradeCard(data: viewModel.gradeAnalysisData)
                    HomeElectricityCard(dorms: viewModel.electricityDorms)
                }
                .padding(.horizontal)

                // 作业与考试
                let columns = sizeClass == .regular ? [GridItem(.flexible(), spacing: 24), GridItem(.flexible(), spacing: 24)] : [GridItem(.flexible(), spacing: 24)]

                LazyVGrid(columns: columns, spacing: 24) {
                    // 待提交作业
                    VStack(spacing: 12) {
                        HomeSectionHeader(
                            title: "待提交作业",
                            icon: "doc.text.fill",
                            color: .red,
                            destination: UrgentCoursesView()
                        )

                        if let urgentData = viewModel.urgentCourseData?.value {
                            if urgentData.courses.isEmpty {
                                HomeEmptyStateView(icon: "doc.text", text: "暂无待提交作业")
                            } else {
                                HomeUrgentListView(courses: urgentData.courses)
                            }
                        } else {
                            HomeEmptyStateView(icon: "doc.text", text: "暂无数据，请前往详情页加载")
                        }
                    }

                    // 考试安排
                    VStack(spacing: 12) {
                        HomeSectionHeader(
                            title: "考试安排",
                            icon: "calendar.badge.clock",
                            color: .orange,
                            destination: ExamScheduleView()
                        )

                        if let examData = viewModel.examScheduleData?.value {
                            if examData.isEmpty {
                                HomeEmptyStateView(icon: "calendar.badge.checkmark", text: "近期没有考试")
                            } else {
                                HomeExamListView(exams: examData)
                            }
                        } else {
                            HomeEmptyStateView(icon: "calendar.badge.exclamationmark", text: "暂无数据，请前往详情页加载")
                        }
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
            .frame(maxWidth: sizeClass == .regular ? 900 : .infinity)
            .frame(maxWidth: .infinity)
            .padding(.top, sizeClass == .regular ? 20 : 0)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            viewModel.loadData()
        }
    }
}

// MARK: - Subviews & Components

private struct HomeHeaderView: View {
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "早上好"
        case 12..<14: return "中午好"
        case 14..<19: return "下午好"
        case 19..<24: return "晚上好"
        default: return "夜深了"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date().formatted(.dateTime.month().day().weekday()))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text(greeting)
                .font(.largeTitle)
                .fontDesign(.rounded)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HomeSectionHeader<Destination: View>: View {
    let title: String
    let icon: String
    let color: Color
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)

                Spacer()

                HStack(spacing: 4) {
                    Text("查看全部")
                    Image(systemName: "chevron.right")
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct HomeEmptyStateView: View {
    let icon: String
    let text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct HomeCourseCarousel: View {
    let data: Cached<CourseScheduleData>?
    private var currentTime: Date { Date() }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader(
                title: "今日课程",
                icon: "book.fill",
                color: .purple,
                destination: CourseScheduleView()
            )
            .padding(.horizontal)

            if let schedule = data?.value {
                let todayCourses = CourseScheduleHelper.getUnfinishedCourses(
                    semesterStartDate: schedule.semesterStartDate,
                    now: currentTime,
                    courses: schedule.courses
                )

                if !todayCourses.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(Array(todayCourses.enumerated()), id: \.offset) { _, item in
                                CourseCard(
                                    course: item.course.course,
                                    session: item.course.session,
                                    isCurrent: item.isCurrent
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 20)
                    }
                } else {
                    EmptyCourseCard()
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }
            } else {
                EmptyCourseCard(text: "暂无课程数据")
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
        }
    }
}

private struct CourseCard: View {
    let course: EduHelper.Course
    let session: EduHelper.ScheduleSession
    let isCurrent: Bool

    @State private var showDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.courseName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(2)
                        .foregroundStyle(.white)

                    if let teacher = course.teacher {
                        Text(teacher)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                Spacer()

                if isCurrent {
                    Text("进行中")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white)
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
            }
            Spacer()
            HStack {
                Label(session.classroom ?? "未知地点", systemImage: "location.fill")
                Spacer()
                Text(formatCourseTime(session.startSection, session.endSection))
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.white.opacity(0.8))
        }
        .padding(16)
        .frame(width: 240, height: 140)
        .background(
            LinearGradient(
                colors: isCurrent ? [.blue, .purple] : [.blue.opacity(0.8), .blue.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: isCurrent ? .blue.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
        .onTapGesture {
            showDetail = true
        }
        .sheet(isPresented: $showDetail) {
            CourseScheduleDetailView(course: course, session: session, isPresented: $showDetail)
        }
    }

    func formatCourseTime(_ startSection: Int, _ endSection: Int) -> String {
        let startIndex = startSection - 1
        let endIndex = endSection - 1

        guard startIndex >= 0 && startIndex < CourseScheduleHelper.sectionTimeString.count,
            endIndex >= 0 && endIndex < CourseScheduleHelper.sectionTimeString.count
        else {
            return "时间未知"
        }

        return "\(CourseScheduleHelper.sectionTimeString[startIndex].0) - \(CourseScheduleHelper.sectionTimeString[endIndex].1)"
    }
}

private struct EmptyCourseCard: View {
    var text: String = "今天没有课，好好休息吧 ~"

    var body: some View {
        HStack {
            Image(systemName: "cup.and.saucer.fill")
                .font(.largeTitle)
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding()
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(.secondary)
    }
}

private struct HomeGradeCard: View {
    let data: Cached<[EduHelper.CourseGrade]>?

    var analysisData: GradeAnalysisData? {
        guard let courseGrades = data?.value else { return nil }
        return GradeAnalysisData.fromCourseGrades(courseGrades)
    }

    var body: some View {
        NavigationLink(destination: GradeAnalysisView()) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.green)
                    Spacer()
                    Text("GPA")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let gradeData = analysisData {
                    Text(String(format: "%.2f", gradeData.overallGPA))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(ColorHelper.dynamicColor(point: gradeData.overallGPA))

                    Text("平均分: \(String(format: "%.1f", gradeData.overallAverageGrade))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("-.-")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("暂无数据")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .frame(height: 130)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct HomeElectricityCard: View {
    let dorms: [Dorm]
    var primaryDorm: Dorm? {
        dorms.first(where: { $0.isFavorite }) ?? dorms.first
    }

    var body: some View {
        NavigationLink(destination: ElectricityQueryView()) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                    Spacer()
                    Text("电量")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let dorm = primaryDorm, let record = dorm.lastRecord {
                    Text(String(format: "%.1f", record.electricity))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(ColorHelper.electricityColor(electricity: record.electricity))

                    HStack {
                        Text("kWh")
                        Spacer()
                        Text(dorm.room)
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                } else {
                    Text("未绑定")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Text("添加宿舍")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            .padding(16)
            .frame(height: 130)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct HomeUrgentListView: View {
    let courses: [UrgentCourseData.Course]

    var displayedCourses: [UrgentCourseData.Course] {
        Array(courses.prefix(2))
    }

    var remainingCount: Int {
        max(0, courses.count - 2)
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(displayedCourses, id: \.name) { course in
                NavigationLink(destination: UrgentCoursesView()) {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.orange)
                            .frame(width: 4, height: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(course.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Text("待提交")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            if remainingCount > 0 {
                NavigationLink(destination: UrgentCoursesView()) {
                    Text("还有 \(remainingCount) 项作业待提交...")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            }
        }
    }
}

private struct HomeExamListView: View {
    let exams: [EduHelper.Exam]

    var displayedExams: [EduHelper.Exam] {
        Array(exams.prefix(2))
    }

    var remainingCount: Int {
        max(0, exams.count - 2)
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(displayedExams, id: \.courseName) { exam in
                HStack {
                    VStack(alignment: .center, spacing: 2) {
                        Image(systemName: "calendar")
                            .font(.title3)
                            .foregroundStyle(.red.opacity(0.8))
                    }
                    .frame(width: 40)

                    Divider()
                        .frame(height: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(exam.courseName)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        HStack(spacing: 6) {
                            Text(exam.examTime)
                            if !exam.examRoom.isEmpty {
                                Text("·")
                                Text(exam.examRoom)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if remainingCount > 0 {
                NavigationLink(destination: ExamScheduleView()) {
                    Text("还有 \(remainingCount) 场考试安排...")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            }
        }
    }
}

#Preview {
    OverviewView()
}
