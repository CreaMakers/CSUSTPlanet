//
//  HomeGradeAnalysisView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import SwiftUI

struct HomeGradeAnalysisView: View {
    let gradeAnalysisData: Cached<[EduHelper.CourseGrade]>?

    struct GradeAnalysisData {
        var totalCourses: Int
        var totalHours: Int
        var totalCredits: Double
        var overallAverageGrade: Double
        var overallGPA: Double
        var weightedAverageGrade: Double
        var gradePointDistribution: [(gradePoint: Double, count: Int)]
        var semesterAverageGrades: [(semester: String, average: Double)]
        var semesterGPAs: [(semester: String, gpa: Double)]
    }

    var analysisData: GradeAnalysisData? {
        guard let courseGrades = gradeAnalysisData?.value else { return nil }
        let totalCourses = courseGrades.count
        let totalHours = courseGrades.reduce(0) { $0 + $1.totalHours }
        let totalCredits = courseGrades.reduce(0) { $0 + $1.credit }
        let overallAverageGrade = totalCourses > 0 ? Double(courseGrades.reduce(0) { $0 + $1.grade }) / Double(totalCourses) : 0.0
        let overallGPA = totalCredits > 0 ? courseGrades.reduce(0) { $0 + $1.gradePoint * $1.credit } / totalCredits : 0.0
        let weightedAverageGrade = totalCredits > 0 ? courseGrades.reduce(0) { $0 + (Double($1.grade) * $1.credit) } / totalCredits : 0.0
        let gradePointDistribution = courseGrades.reduce(into: [Double: Int]()) { result, course in
            result[course.gradePoint, default: 0] += 1
        }.map { (gradePoint: $0.key, count: $0.value) }
        let semesterAverageGrades = Dictionary(grouping: courseGrades, by: { $0.semester }).map { semester, grades in
            (semester: semester, average: Double(grades.reduce(0) { $0 + $1.grade }) / Double(grades.count))
        }
        let semesterGPAs = Dictionary(grouping: courseGrades, by: { $0.semester }).map { semester, grades in
            let totalCredits = grades.reduce(0) { $0 + $1.credit }
            let totalGradePoints = grades.reduce(0) { $0 + $1.gradePoint * $1.credit }
            let gpa = totalCredits > 0 ? totalGradePoints / totalCredits : 0.0
            return (semester: semester, gpa: gpa)
        }
        return GradeAnalysisData(
            totalCourses: totalCourses,
            totalHours: totalHours,
            totalCredits: totalCredits,
            overallAverageGrade: overallAverageGrade,
            overallGPA: overallGPA,
            weightedAverageGrade: weightedAverageGrade,
            gradePointDistribution: gradePointDistribution.sorted { $0.gradePoint > $1.gradePoint },
            semesterAverageGrades: semesterAverageGrades.sorted { $0.semester < $1.semester },
            semesterGPAs: semesterGPAs.sorted { $0.semester < $1.semester }
        )
    }

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
            if let gradeData = analysisData {
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
