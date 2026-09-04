//
//  ScheduleEventRow.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/9/4.
//

import SwiftUI

struct ScheduleEventRow: View {
    let event: ScheduleEvent
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 0) {
                timeColumn
                Rectangle()
                    .fill(Color.primary.opacity(0.12))
                    .frame(width: 1)
                    .padding(.vertical, 8)
                eventContent
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(
                event.kind.presentationTint.opacity(0.09),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private var timeColumn: some View {
        VStack(alignment: .center, spacing: 3) {
            switch event.timing {
            case .interval(let start, let end):
                Text(ScheduleDateUtil.timeFormatter.string(from: start))
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Text(ScheduleDateUtil.timeFormatter.string(from: end))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            case .point(let at):
                Text(ScheduleDateUtil.timeFormatter.string(from: at))
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Text("截止")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 64, alignment: .center)
        .padding(.top, 8)
    }

    private var eventContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(event.content.title)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(event.kind.presentationTitle)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(event.kind.presentationTint)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        event.kind.presentationTint.opacity(0.12),
                        in: Capsule()
                    )
            }

            if let subtitle = event.content.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if let location = event.content.location, !location.isEmpty {
                Text(location)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .padding(.vertical, 8)
    }

}

#Preview("ScheduleEventRow") {
    VStack(spacing: 12) {
        ScheduleEventRow(event: SchedulePreviewData.events[0], onTap: {})
        ScheduleEventRow(event: SchedulePreviewData.events[2], onTap: {})
    }
    .padding()
}
