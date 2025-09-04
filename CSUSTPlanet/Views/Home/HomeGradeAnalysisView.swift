//
//  HomeGradeAnalysisView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import SwiftUI

struct HomeGradeAnalysisView: View {
    let gradeAnalysisData: GradeAnalysisData?

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            NavigationLink(destination: GradeAnalysisView()) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.green)

                        Text("成绩分析")
                            .foregroundColor(.primary)
                    }
                    .font(.headline)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            Divider()

            // 内容
            if let gradeData = gradeAnalysisData {
                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        gradeStatItem(title: "GPA", value: String(format: "%.2f", gradeData.overallGPA), color: .blue)
                        gradeStatItem(title: "平均成绩", value: String(format: "%.1f", gradeData.overallAverageGrade), color: .green)
                        gradeStatItem(title: "已修学分", value: String(format: "%.0f", gradeData.totalCredits), color: .orange)
                    }
                }
                .padding(16)
            } else {
                emptyStateView(
                    icon: "chart.bar",
                    title: "暂无成绩数据",
                    description: "请前往成绩分析页面加载数据"
                )
                .padding(.vertical, 20)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func gradeStatItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func emptyStateView(icon: String, title: String, description: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.secondary)

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeGradeAnalysisView(gradeAnalysisData: nil)
}
