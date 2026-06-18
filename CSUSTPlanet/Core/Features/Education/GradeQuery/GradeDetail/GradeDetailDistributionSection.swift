//
//  GradeDetailDistributionSection.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/18.
//

import CSUSTKit
import Charts
import SwiftUI

struct GradeDetailDistributionSection: View {
    let detail: EduHelper.GradeDetail?
    @Binding var renderMode: GradeDetailRenderMode

    var body: some View {
        if let detail {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 12) {
                    Text("成绩分布")
                        .font(.headline)
                    Spacer()
                    Picker("显示方式", selection: $renderMode.withAnimation()) {
                        ForEach(GradeDetailRenderMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
                .padding(.horizontal)

                CustomGroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        if renderMode == .pie {
                            pieChart(detail)
                        } else {
                            progressList(detail)
                        }
                    }
                }
            }
        }
    }

    private func pieChart(_ detail: EduHelper.GradeDetail) -> some View {
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

    private func progressList(_ detail: EduHelper.GradeDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(detail.components, id: \.type) { component in
                progressRow(
                    title: "\(component.type) (\(component.ratio)%)",
                    gradeText: "\(String(format: "%.1f", component.grade))/100",
                    value: component.grade
                )
            }

            progressRow(
                title: "总成绩 (100%)",
                gradeText: "\(String(format: "%.1f", Double(detail.totalGrade)))/100",
                value: Double(detail.totalGrade)
            )
        }
    }

    private func progressRow(title: String, gradeText: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.callout)
                Spacer()
                Text(gradeText)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: min(max(value, 0), 100), total: 100)
                .tint(ColorUtil.dynamicColor(grade: value))
        }
    }
}

#Preview("GradeDetailDistributionSection Progress") {
    @Previewable @State var renderMode = GradeDetailRenderMode.progress

    GradeDetailDistributionSection(
        detail: GradeQueryPreviewData.detail,
        renderMode: $renderMode
    )
    .padding()
}

#Preview("GradeDetailDistributionSection Pie") {
    @Previewable @State var renderMode = GradeDetailRenderMode.pie

    GradeDetailDistributionSection(
        detail: GradeQueryPreviewData.detail,
        renderMode: $renderMode
    )
    .padding()
}
