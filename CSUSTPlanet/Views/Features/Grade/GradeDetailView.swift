//
//  GradeDetailView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/12.
//

import Charts
import CSUSTKit
import SwiftUI

struct GradeDetailView: View {
    @StateObject var viewModel: GradeDetailViewModel
    
    init(authManager: AuthManager, courseGrade: CourseGrade) {
        _viewModel = StateObject(wrappedValue: GradeDetailViewModel(eduHelper: authManager.eduHelper, courseGrade: courseGrade))
    }
    
    var body: some View {
        List {
            Section(header: Text("基本信息")) {
                DetailRow(label: "课程名称", value: viewModel.courseGrade.courseName)
                DetailRow(label: "课程编号", value: viewModel.courseGrade.courseID)
                DetailRow(label: "开课学期", value: viewModel.courseGrade.semester)
                DetailRow(label: "分组名", value: viewModel.courseGrade.groupName)
                DetailRow(label: "修读方式", value: viewModel.courseGrade.studyMode)
            }
            
            Section(header: Text("成绩信息")) {
                Gauge(value: Float(viewModel.courseGrade.grade), in: 0 ... 100) {
                    Text("总成绩")
                        .font(.headline)
                } currentValueLabel: {
                    Text("\(viewModel.courseGrade.grade)")
                        .font(.title2)
                        .bold()
                }
                Gauge(value: viewModel.courseGrade.gradePoint, in: 0 ... 4) {
                    Text("绩点")
                        .font(.headline)
                } currentValueLabel: {
                    Text(String(format: "%.1f", viewModel.courseGrade.gradePoint))
                        .font(.title2)
                        .bold()
                }
                DetailRow(label: "学分", value: String(format: "%.1f", viewModel.courseGrade.credit))
                DetailRow(label: "总学时", value: "\(viewModel.courseGrade.totalHours)")
            }
            
            if let detail = viewModel.gradeDetail {
                Section(header: Text("成绩分布")) {
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
            } else if viewModel.isLoadingDetail {
                Section(header: Text("成绩详细")) {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            }
            
            Section(header: Text("课程属性")) {
                DetailRow(label: "课程性质", value: viewModel.courseGrade.courseNature.rawValue)
                DetailRow(label: "课程类别", value: viewModel.courseGrade.courseCategory)
                DetailRow(label: "课程属性", value: viewModel.courseGrade.courseAttribute)
                DetailRow(label: "考核方式", value: viewModel.courseGrade.assessmentMethod)
                DetailRow(label: "考试性质", value: viewModel.courseGrade.examNature)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("成绩详细")
        .task {
            viewModel.loadDetail()
        }
        .alert("错误", isPresented: $viewModel.isShowingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.loadDetail()
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
            }
        }
    }
    
    struct DetailRow: View {
        let label: String
        let value: String
        
        var body: some View {
            HStack {
                Text(label)
                Spacer()
                Text(value).foregroundColor(.secondary)
            }
        }
    }
}
