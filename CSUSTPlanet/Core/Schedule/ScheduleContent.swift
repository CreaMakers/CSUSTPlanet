//
//  ScheduleContent.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/9/4.
//

import SwiftUI
import SwiftUIIntrospect

#if os(iOS)
import UIKit
#endif

#if os(iOS)
private final class WeakUIScrollViewReference: ObservableObject {
    weak var scrollView: UIScrollView?
}
#endif

struct ScheduleContent: View {
    let timeline: ScheduleTimelineData
    let isInitialDataReady: Bool

    @State private var visibleSectionID: ScheduleTimelineSectionID?
    @State private var selectedDayID: Date?
    @State private var selectedEvent: ScheduleEvent?
    @State private var hasPerformedInitialScroll = false
    #if os(iOS)
    @StateObject private var scheduleScrollViewReference = WeakUIScrollViewReference()
    #endif

    var body: some View {
        CustomScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(timeline.sections) { section in
                    Group {
                        switch section {
                        case .day(let daySection):
                            ScheduleDaySectionView(
                                section: daySection,
                                referenceDate: timeline.referenceDate,
                                currentIndicatorPlacement: timeline.currentIndicatorPlacement,
                                onSelectEvent: { selectedEvent = $0 }
                            )
                        case .empty(let emptySection):
                            ScheduleEmptySectionView(
                                section: emptySection,
                                referenceDate: timeline.referenceDate,
                                showsIndicator: showsIndicator(in: emptySection)
                            )
                        }
                    }
                    .id(section.id)
                }
            }
            .scrollTargetLayout()
            #if os(iOS)
            .introspect(.scrollView, on: .iOS(.v17, .v18, .v26), scope: .ancestor) { scrollView in
                scheduleScrollViewReference.scrollView = scrollView
            }
            #endif
        }
        .scrollPosition(id: $visibleSectionID, anchor: .top)
        .safeAreaInset(edge: .top, spacing: 0) {
            ScheduleDateHeader(
                dates: ScheduleDateUtil.datesForWeek(containing: headerDayID),
                activeDate: headerDayID,
                referenceDate: timeline.referenceDate,
                eventDates: timeline.eventDates,
                onSelectDate: { date in
                    scrollToNearestDate(date)
                }
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
                .disabled(ScheduleDateUtil.isSameDay(headerDayID, todayID))
            }
        }
        .task(id: initialScrollTargetID) {
            guard
                isInitialDataReady,
                !hasPerformedInitialScroll,
                let targetSectionID = initialScrollTargetID
            else {
                return
            }

            if isOnlyTodayEmptySection {
                hasPerformedInitialScroll = true
                return
            }

            await Task.yield()

            guard
                !Task.isCancelled,
                !hasPerformedInitialScroll,
                let targetSection = timeline.sections.first(where: { $0.id == targetSectionID })
            else {
                return
            }

            selectedDayID = dayID(for: targetSection)
            visibleSectionID = targetSectionID
            hasPerformedInitialScroll = true
        }
        .onChange(of: visibleSectionID) { _, newVisibleSectionID in
            guard
                let newVisibleSectionID,
                let visibleSection = timeline.sections.first(where: { $0.id == newVisibleSectionID })
            else {
                return
            }

            selectedDayID = dayID(for: visibleSection)
        }
        .sheet(item: $selectedEvent) { event in
            NavigationStack {
                ScheduleEventDetailView(event: event)
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var headerDayID: Date {
        selectedDayID ?? activeDayID
    }

    private func showsIndicator(in section: ScheduleEmptySection) -> Bool {
        guard case .some(.inEmptySection(let sectionID)) = timeline.currentIndicatorPlacement else {
            return false
        }

        return sectionID == section.id
    }

    private var todayID: Date {
        ScheduleDateUtil.startOfDay(for: timeline.referenceDate)
    }

    private var initialScrollTargetID: ScheduleTimelineSectionID? {
        guard isInitialDataReady, !hasPerformedInitialScroll else {
            return nil
        }

        return timeline.sections.first(where: { $0.contains(todayID) })?.id
    }

    private var isOnlyTodayEmptySection: Bool {
        guard
            timeline.sections.count == 1,
            case .empty(let section) = timeline.sections[0]
        else {
            return false
        }

        return ScheduleDateUtil.isSameDay(section.startDate, todayID)
            && ScheduleDateUtil.isSameDay(section.endDate, todayID)
    }

    private var activeDayID: Date {
        guard
            let visibleSectionID,
            let visibleSection = timeline.sections.first(where: { $0.id == visibleSectionID })
        else {
            return todayID
        }

        return dayID(for: visibleSection)
    }

    private func dayID(for section: ScheduleTimelineSection) -> Date {
        switch section {
        case .day(let daySection):
            return daySection.id
        case .empty(let emptySection):
            return emptySection.contains(todayID) ? todayID : emptySection.startDate
        }
    }

    private func scrollToNearestDate(_ date: Date) {
        guard let targetSection = targetSection(for: date) else {
            return
        }

        selectedDayID = dayID(for: targetSection)

        #if os(iOS)
        if let scheduleScrollView = scheduleScrollViewReference.scrollView {
            scheduleScrollView.setContentOffset(scheduleScrollView.contentOffset, animated: false)
        }
        #endif

        let targetSectionID = targetSection.id
        let visibleSectionBinding = $visibleSectionID
        DispatchQueue.main.async {
            visibleSectionBinding.wrappedValue = targetSectionID
        }
    }

    private func targetSection(for date: Date) -> ScheduleTimelineSection? {
        if let targetSection = timeline.sections.first(where: { $0.contains(date) }) {
            return targetSection
        }

        let daySections = timeline.sections.filter {
            if case .day = $0 {
                return true
            }

            return false
        }

        guard let firstDaySection = daySections.first, let lastDaySection = daySections.last else {
            return nil
        }

        let targetDay = ScheduleDateUtil.startOfDay(for: date)

        if targetDay < dayID(for: firstDaySection) {
            return firstDaySection
        }

        if targetDay > dayID(for: lastDaySection) {
            return lastDaySection
        }

        return nil
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
            timeline: timeline,
            isInitialDataReady: true
        )
    }
}
