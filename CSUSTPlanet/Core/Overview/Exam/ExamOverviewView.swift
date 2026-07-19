//
//  ExamOverviewView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import SwiftUI

struct ExamOverviewView: View {
    @State private var viewModel = ExamOverviewViewModel()
    @Environment(Router.self) private var router

    var body: some View {
        let pendingExams = viewModel.pendingExams

        Button(action: { router.deepLinkTo(feature: .examSchedule) }) {
            CustomGroupBox {
                cardContent(pendingExams: pendingExams)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func cardContent(pendingExams: [EduHelper.Exam]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("考试安排")
                    .font(.title3)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)

                Spacer()

                if let lastUpdated = viewModel.cachedAt {
                    LastUpdatedDateView(
                        lastUpdated: lastUpdated,
                        font: .footnote,
                        foregroundStyle: .secondary
                    )
                    .contentTransition(.numericText())
                }

                Button(asyncAction: viewModel.loadExams) {
                    Image(systemName: "arrow.clockwise.circle")
                }
                .disabled(viewModel.isLoadingExams)
            }

            if pendingExams.isEmpty {
                EmptyExamContentView()
                    .redacted(reason: viewModel.isLoadingExams ? .placeholder : [])
            } else {
                ExamListView(
                    pendingExams: pendingExams,
                    daysUntilExam: viewModel.daysUntilExam
                )
                .redacted(reason: viewModel.isLoadingExams ? .placeholder : [])
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

private struct ExamListView: View {
    let pendingExams: [EduHelper.Exam]
    let daysUntilExam: (EduHelper.Exam) -> Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(pendingExams.enumerated()), id: \.offset) { _, exam in
                ExamRowView(exam: exam, daysUntilExam: daysUntilExam(exam))
            }
        }
    }
}

private struct ExamRowView: View {
    let exam: EduHelper.Exam
    let daysUntilExam: Int

    private var dateStyle: RelativeDateStyle {
        RelativeDateStyle.scheduled(for: exam.examStartTime)
    }

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(dateStyle.accentColor)
                .frame(width: 4)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exam.courseName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(locationText)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 2)

                VStack(alignment: .trailing, spacing: 4) {
                    RelativeDateBadge(
                        text: statusText,
                        style: dateStyle
                    )

                    Text(timeRangeText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(dateStyle.cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var statusText: String {
        switch daysUntilExam {
        case 0:
            return "今天"
        case 1:
            return "明天"
        case 2:
            return "后天"
        default:
            return "还有 \(daysUntilExam) 天"
        }
    }

    private var locationText: String {
        exam.examRoom.isEmpty ? "地点待定" : exam.examRoom
    }

    private var timeRangeText: String {
        let start = exam.examStartTime.formatted(.dateTime.month().day().hour().minute())
        let end = exam.examEndTime.formatted(.dateTime.hour().minute())
        return "\(start)-\(end)"
    }
}

private struct EmptyExamContentView: View {
    var body: some View {
        Text("暂无考试安排")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
    }
}
