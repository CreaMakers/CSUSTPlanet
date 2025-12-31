//
//  SchoolCalendarListView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/23.
//

import SwiftUI

struct SchoolCalendarListView: View {
    @StateObject var viewModel = SchoolCalendarListViewModel()

    var body: some View {
        List(viewModel.schoolCalendars) { calendar in
            TrackLink(destination: SchoolCalendarView(semester: calendar.semester)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(calendar.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(calendar.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Button(action: viewModel.loadSchoolCalendars) {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            viewModel.loadSchoolCalendars()
        }
        .refreshable {
            viewModel.loadSchoolCalendars()
        }
        .navigationTitle("校历列表")
        .trackView("SchoolCalendarList")
    }
}

#Preview {
    SchoolCalendarListView()
}
