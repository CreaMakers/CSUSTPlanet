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
                HomeHeaderView(greeting: viewModel.greeting, weekInfo: viewModel.weekInfo)
                    .padding(.horizontal)
                    .padding(.top, 10)

                // 今日课程
                HomeCourseCarousel(viewModel: viewModel)

                // 核心数据网格 (成绩 + 电量)
                HStack(spacing: 16) {
                    HomeGradeCard(analysisData: viewModel.currentGradeAnalysis)
                    HomeElectricityCard(primaryDorm: viewModel.primaryDorm, exhaustionInfo: viewModel.electricityExhaustionInfo)
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
                            destination: UrgentCoursesView().track(["App", "Overview", "UrgentCourses"])
                        )

                        let courses = viewModel.urgentCourses
                        if courses.isEmpty {
                            if viewModel.urgentCoursesData?.value == nil {
                                HomeEmptyStateView(icon: "doc.text", text: "暂无数据，请前往详情页加载")
                            } else {
                                HomeEmptyStateView(icon: "doc.text", text: "暂无待提交作业")
                            }
                        } else {
                            HomeUrgentListView(viewModel: viewModel)
                        }
                    }

                    // 考试安排
                    VStack(spacing: 12) {
                        HomeSectionHeader(
                            title: "考试安排",
                            icon: "calendar.badge.clock",
                            color: .orange,
                            destination: ExamScheduleView().track(["App", "Overview", "ExamSchedule"])
                        )

                        let pendingExams = viewModel.pendingExams
                        if pendingExams.isEmpty {
                            if viewModel.examScheduleData?.value == nil {
                                HomeEmptyStateView(icon: "calendar.badge.exclamationmark", text: "暂无数据，请前往详情页加载")
                            } else {
                                HomeEmptyStateView(icon: "calendar.badge.checkmark", text: "近期没有考试")
                            }
                        } else {
                            HomeExamListView(viewModel: viewModel)
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
    let greeting: String
    let weekInfo: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(Date().formatted(.dateTime.month().day().weekday()))
                if let weekInfo {
                    Text("·")
                    Text(weekInfo)
                }
            }
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
    @ObservedObject var viewModel: OverviewViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader(
                title: "今日课程",
                icon: "book.fill",
                color: .purple,
                destination: CourseScheduleView().track(["App", "Overview", "CourseSchedule"])
            )
            .padding(.horizontal)

            if let todaysFinishedCourses = viewModel.todayCourses {
                if !todaysFinishedCourses.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(Array(todaysFinishedCourses.enumerated()), id: \.offset) { _, item in
                                CourseCard(
                                    course: item.course.course,
                                    session: item.course.session,
                                    isCurrent: item.isCurrent,
                                    viewModel: viewModel
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                } else {
                    EmptyCourseCard()
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                }
            } else {
                EmptyCourseCard(text: "暂无课程数据")
                    .padding(.horizontal)
                    .padding(.bottom, 10)
            }
        }
    }
}

private struct CourseCard: View {
    let course: EduHelper.Course
    let session: EduHelper.ScheduleSession
    let isCurrent: Bool
    @ObservedObject var viewModel: OverviewViewModel

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
                Text(viewModel.formatCourseTime(session.startSection, session.endSection))
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
    let analysisData: GradeAnalysisData?

    var body: some View {
        NavigationLink(destination: GradeAnalysisView().track(["App", "Overview", "GradeAnalysis"])) {
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
                        .foregroundStyle(ColorUtil.dynamicColor(point: gradeData.overallGPA))

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
    let primaryDorm: Dorm?
    let exhaustionInfo: String?

    var body: some View {
        NavigationLink(destination: ElectricityQueryView().track(["App", "Overview", "ElectricityQuery"])) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                    Spacer()
                    if let dorm = primaryDorm {
                        Text(dorm.room)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let dorm = primaryDorm, let record = dorm.lastRecord {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", record.electricity))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(ColorUtil.electricityColor(electricity: record.electricity))

                        Text("kWh")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                    }

                    if let info = exhaustionInfo {
                        Text(info)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
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
    @ObservedObject var viewModel: OverviewViewModel

    var body: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.displayedUrgentCourses, id: \.name) { course in
                NavigationLink(destination: UrgentCoursesView().track(["App", "Overview", "UrgentCourses"])) {
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

            if viewModel.urgentCoursesRemainingCount > 0 {
                NavigationLink(destination: UrgentCoursesView().track(["App", "Overview", "UrgentCourses"])) {
                    Text("还有 \(viewModel.urgentCoursesRemainingCount) 项作业待提交...")
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
    @ObservedObject var viewModel: OverviewViewModel

    var body: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.displayedExams, id: \.courseName) { exam in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exam.courseName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            Text(exam.examTime)
                            if !exam.examRoom.isEmpty {
                                Text("·")
                                Text(exam.examRoom)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    }

                    Spacer()

                    let daysLeft = viewModel.daysUntilExam(exam)
                    if daysLeft == 0 {
                        Text("今天")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red, in: Capsule())
                    } else if daysLeft == 1 {
                        Text("明天")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange, in: Capsule())
                    } else {
                        Text("还有 \(daysLeft) 天")
                            .font(.caption.bold())
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1), in: Capsule())
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if viewModel.examsRemainingCount > 0 {
                NavigationLink(destination: ExamScheduleView().track(["App", "Overview", "ExamSchedule"])) {
                    Text("还有 \(viewModel.examsRemainingCount) 场考试安排...")
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
