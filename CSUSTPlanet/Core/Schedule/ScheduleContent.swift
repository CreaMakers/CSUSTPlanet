//
//  ScheduleContent.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/9/4.
//

import SwiftUI

struct ScheduleContent: View {
    let sections: [ScheduleTimelineSection]
    let eventDates: Set<Date>
    let referenceDate: Date
    let currentIndicatorPlacement: ScheduleCurrentIndicatorPlacement?

    @State private var visibleSectionID: ScheduleTimelineSectionID?
    @State private var selectedEvent: ScheduleEvent?
    @State private var hasPerformedInitialScroll = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(sections) { section in
                    Group {
                        switch section {
                        case .day(let daySection):
                            ScheduleDaySectionView(
                                section: daySection,
                                referenceDate: referenceDate,
                                currentIndicatorPlacement: currentIndicatorPlacement,
                                onSelectEvent: { selectedEvent = $0 }
                            )
                        case .empty(let emptySection):
                            ScheduleEmptySectionView(
                                section: emptySection,
                                referenceDate: referenceDate,
                                showsIndicator: showsIndicator(in: emptySection)
                            )
                        }
                    }
                    .id(section.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $visibleSectionID, anchor: .top)
        .safeAreaInset(edge: .top, spacing: 0) {
            ScheduleDateHeader(
                dates: ScheduleDateUtil.datesForWeek(containing: activeDayID),
                activeDate: activeDayID,
                referenceDate: referenceDate,
                eventDates: eventDates,
                onSelectDate: scrollToNearestDate
            )
            .frame(maxWidth: 700)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("日程")
        .inlineToolbarTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("今天") {
                    scrollToNearestDate(todayID)
                }
                .disabled(ScheduleDateUtil.isSameDay(activeDayID, todayID))
            }
        }
        .onChange(of: sectionIDs, initial: true) { _, _ in
            guard
                !hasPerformedInitialScroll,
                let todaySectionID = sections.first(where: { $0.contains(todayID) })?.id
            else {
                return
            }

            hasPerformedInitialScroll = true
            visibleSectionID = todaySectionID
        }
        .sheet(item: $selectedEvent) { event in
            NavigationStack {
                ScheduleEventDetailView(event: event)
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func showsIndicator(in section: ScheduleEmptySection) -> Bool {
        guard case .some(.inEmptySection(let sectionID)) = currentIndicatorPlacement else {
            return false
        }

        return sectionID == section.id
    }

    private var sectionIDs: [ScheduleTimelineSectionID] {
        sections.map(\.id)
    }

    private var todayID: Date {
        ScheduleDateUtil.startOfDay(for: referenceDate)
    }

    private var activeDayID: Date {
        guard
            let visibleSectionID,
            let visibleSection = sections.first(where: { $0.id == visibleSectionID })
        else {
            return todayID
        }

        switch visibleSection {
        case .day(let section):
            return section.id
        case .empty(let section):
            return section.contains(todayID) ? todayID : section.startDate
        }
    }

    private func scrollToNearestDate(_ date: Date) {
        guard let targetSectionID = sections.first(where: { $0.contains(date) })?.id else {
            return
        }

        withAnimation {
            visibleSectionID = targetSectionID
        }
    }
}

#Preview("ScheduleContent") {
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
