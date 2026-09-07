//
//  ScheduleView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/9/3.
//

import SwiftUI

struct ScheduleView: View {
    @State private var events: [ScheduleEvent] = []
    @State private var referenceDate: Date = .now

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let timeline = ScheduleTimelineBuilder.makeData(
            events: events,
            referenceDate: referenceDate
        )

        ScheduleContent(
            sections: timeline.sections,
            eventDates: timeline.eventDates,
            referenceDate: referenceDate,
            currentIndicatorPlacement: timeline.currentIndicatorPlacement
        )
        .onReceive(ScheduleEventStore.shared.eventsPublisher.receive(on: RunLoop.main)) { events in
            self.events = events
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else {
                return
            }

            await refreshReferenceDate()
        }
    }

    private func refreshReferenceDate() async {
        while !Task.isCancelled {
            let now = Date.now
            referenceDate = now

            guard
                let startOfMinute = ScheduleDateUtil.calendar.date(
                    bySetting: .second,
                    value: 0,
                    of: now
                ),
                let nextMinute = ScheduleDateUtil.calendar.date(
                    byAdding: .minute,
                    value: 1,
                    to: startOfMinute
                )
            else {
                return
            }

            let delay = max(nextMinute.timeIntervalSince(now), 0.1)

            do {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            } catch {
                return
            }
        }
    }
}

#Preview("ScheduleView") {
    NavigationStack {
        let referenceDate = SchedulePreviewData.referenceDate
        let timeline = ScheduleTimelineBuilder.makeData(
            events: SchedulePreviewData.events,
            referenceDate: referenceDate
        )

        ScheduleContent(
            sections: timeline.sections,
            eventDates: timeline.eventDates,
            referenceDate: referenceDate,
            currentIndicatorPlacement: timeline.currentIndicatorPlacement
        )
    }
}
