//
//  PhysicsExperimentGradeView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/11/3.
//

import AlertToast
import CSUSTKit
import SwiftUI

struct PhysicsExperimentGradeView: View {
    @StateObject var viewModel = PhysicsExperimentGradeViewModel()
    @State private var isLoginPresented: Bool = false

    var body: some View {
        Form {
            if viewModel.data.isEmpty {
                emptyStateSection
            } else {
                gradeListSection
            }
        }
        .toast(isPresenting: $viewModel.isShowingError) {
            AlertToast(type: .error(.red), title: "错误", subTitle: viewModel.warningMessage)
        }
        .sheet(isPresented: $isLoginPresented) {
            PhysicsExperimentLoginView(isPresented: $isLoginPresented)
        }
        .onChange(
            of: isLoginPresented,
            { _, newValue in
                if newValue == false {
                    viewModel.loadGrades()
                }
            }
        )
        .task {
            guard !viewModel.isLoaded else { return }
            viewModel.isLoaded = true
            viewModel.loadGrades()
        }
        .navigationTitle("大物实验成绩")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    isLoginPresented = true
                }) {
                    Text("登录")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.9, anchor: .center)
                } else {
                    Button(action: viewModel.loadGrades) {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }

    // MARK: - Form Sections

    private var emptyStateSection: some View {
        Section {
            VStack(spacing: 8) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)

                Text("暂无成绩信息")
                    .font(.headline)

                Text("没有找到任何大物实验成绩信息")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }

    private var gradeListSection: some View {
        Section {
            ForEach(viewModel.data, id: \.itemName) { grade in
                gradeCard(grade: grade)
            }
        }
    }

    private func gradeCard(grade: PhysicsExperimentHelper.CourseGrade) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // 项目名称
            Text(grade.itemName)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(2)

            // 成绩详情
            VStack(spacing: 6) {
                HStack {
                    // 预习成绩
                    gradeItem(label: "预习", score: grade.previewGrade, color: .purple)
                    Spacer()
                    // 操作成绩
                    gradeItem(label: "操作", score: grade.operationGrade, color: .blue)
                    Spacer()
                    // 报告成绩
                    gradeItem(label: "报告", score: grade.reportGrade, color: .green)
                }

                // 总成绩
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .imageScale(.small)
                        Text("总成绩")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    Spacer()
                    Text("\(grade.totalGrade)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(ColorHelper.dynamicColor(grade: Double(grade.totalGrade)))
                }
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 6)
    }

    private func infoItem(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .imageScale(.small)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func gradeItem(label: String, score: Int?, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let score = score {
                Text("\(score)")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
            } else {
                Text("-")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    PhysicsExperimentGradeView()
}
