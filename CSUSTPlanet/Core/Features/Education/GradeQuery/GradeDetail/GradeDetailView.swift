//
//  GradeDetailView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/12.
//

import AlertToast
import CSUSTKit
import Charts
import SwiftUI

struct GradeDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject var viewModel: GradeDetailViewModel

    init(courseGrade: EduHelper.CourseGrade) {
        _viewModel = StateObject(wrappedValue: GradeDetailViewModel(courseGrade))
    }

    // MARK: - Course Title

    private var courseTitle: some View {
        Text(viewModel.courseGrade.courseName)
            .font(.largeTitle)
            .bold()
            .padding(.horizontal)
    }

    // MARK: - Score Item

    private func scoreItem(value: String, label: String, color: Color) -> some View {
        VStack {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Scores Section

    private var scoresSection: some View {
        HStack(alignment: .top, spacing: 16) {
            scoreItem(value: "\(viewModel.courseGrade.grade)", label: "总成绩", color: ColorHelper.dynamicColor(grade: Double(viewModel.courseGrade.grade)))
            scoreItem(value: String(format: "%.1f", viewModel.courseGrade.gradePoint), label: "绩点", color: ColorHelper.dynamicColor(point: viewModel.courseGrade.gradePoint))
            scoreItem(value: String(format: "%.1f", viewModel.courseGrade.credit), label: "学分", color: .primary)
            scoreItem(value: "\(viewModel.courseGrade.totalHours)", label: "学时", color: .primary)
        }
        .padding(.horizontal)
    }

    // MARK: - Distribution Chart

    @ViewBuilder
    private var distributionChart: some View {
        if let detail = viewModel.gradeDetail {
            infoGroupBox(title: "成绩分布") {
                Chart(detail.components, id: \.type) { component in
                    SectorMark(
                        angle: .value("占比", component.ratio),
                        innerRadius: .ratio(0.4),
                        angularInset: 1
                    )
                    .foregroundStyle(by: .value("类型", component.type))
                    .annotation(position: .overlay) {
                        VStack {
                            Text(String(format: "%.1f", component.grade))
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .bold()
                            Text("(\(component.ratio)%)")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
                .frame(height: 250)
                .chartLegend(position: .bottom, alignment: .center, spacing: 10)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Detail Row

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.callout)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .font(.callout)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Course Info Section

    private var courseInfoSection: some View {
        infoGroupBox(title: "课程信息") {
            detailRow(label: "课程编号", value: viewModel.courseGrade.courseID)
            detailRow(label: "开课学期", value: viewModel.courseGrade.semester)
            if !viewModel.courseGrade.groupName.isEmpty {
                detailRow(label: "分组名", value: viewModel.courseGrade.groupName)
            }
            detailRow(label: "修读方式", value: viewModel.courseGrade.studyMode)
            detailRow(label: "课程性质", value: viewModel.courseGrade.courseNature.rawValue)
            if !viewModel.courseGrade.courseCategory.isEmpty {
                detailRow(label: "课程类别", value: viewModel.courseGrade.courseCategory)
            }
            detailRow(label: "课程属性", value: viewModel.courseGrade.courseAttribute)
            detailRow(label: "考核方式", value: viewModel.courseGrade.assessmentMethod)
            detailRow(label: "考试性质", value: viewModel.courseGrade.examNature)
        }
    }

    // MARK: - Info Group Box

    private func infoGroupBox<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.leading)
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }

    // MARK: - Shareable View

    private var shareableView: some View {
        VStack(alignment: .leading, spacing: 24) {
            courseTitle
            scoresSection
            distributionChart
            courseInfoSection
        }
        .padding()
        .frame(width: UIScreen.main.bounds.width)
        .background(Color(.systemGroupedBackground))
        .environment(\.colorScheme, colorScheme)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                courseTitle
                scoresSection
                distributionChart
                courseInfoSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.task() }
        .toast(isPresenting: $viewModel.isShowingError) {
            AlertToast(type: .error(.red), title: "错误", subTitle: viewModel.errorMessage)
        }
        .toast(isPresenting: $viewModel.isShowingSuccess) {
            AlertToast(type: .complete(.green), title: "图片保存成功")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { viewModel.showShareSheet(shareableView) }) {
                        Label("分享", systemImage: "square.and.arrow.up")
                    }
                    .disabled(viewModel.isLoading)
                    Button(action: { viewModel.saveToPhotoAlbum(shareableView) }) {
                        Label("保存结果到相册", systemImage: "photo")
                    }
                    .disabled(viewModel.isLoading)
                } label: {
                    Label("更多操作", systemImage: "ellipsis.circle")
                }
                .disabled(viewModel.isLoading)
            }
            ToolbarItem(placement: .primaryAction) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.9, anchor: .center)
                } else {
                    Button(action: viewModel.loadDetail) {
                        Label("刷新成绩分布", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingShareSheet) {
            ShareSheet(items: [viewModel.shareContent!])
        }
    }
}
