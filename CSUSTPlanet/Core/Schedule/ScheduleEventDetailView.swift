//
//  ScheduleEventDetailView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/9/4.
//

import SwiftUI

struct ScheduleEventDetailView: View {
    let event: ScheduleEvent

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(event.kind.presentationTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(event.kind.presentationTint)

                    Text(event.content.title)
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.leading)

                    if let subtitle = event.content.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let location = event.content.location, !location.isEmpty {
                        Text(location)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }

            Section("时间") {
                switch event.timing {
                case .interval(let start, let end):
                    LabeledContent("开始", value: ScheduleDateUtil.detailDateFormatter.string(from: start))
                    LabeledContent("结束", value: ScheduleDateUtil.detailDateFormatter.string(from: end))
                case .point(let at):
                    LabeledContent(
                        "截止",
                        value: ScheduleDateUtil.detailDateFormatter.string(from: at)
                    )
                }
            }

            if !event.content.details.isEmpty {
                Section("详细信息") {
                    ForEach(event.content.details, id: \.self) { detail in
                        LabeledContent(detail.label, value: detail.value)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("日程详情")
        .inlineToolbarTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("关闭") {
                    dismiss()
                }
            }
        }
    }
}

#Preview("ScheduleEventDetailView") {
    NavigationStack {
        ScheduleEventDetailView(event: SchedulePreviewData.events[0])
    }
}
