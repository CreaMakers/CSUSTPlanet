//
//  SchoolCalendarListView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/23.
//

import AlertToast
import SwiftUI

struct SchoolCalendarListView: View {
    @State var viewModel = SchoolCalendarListViewModel()

    var body: some View {
        Group {
            if viewModel.schoolCalendars.isEmpty {
                ContentUnavailableView("无校历数据", systemImage: "calendar.badge.exclamationmark")
            } else {
                CustomScrollView {
                    ForEach(viewModel.schoolCalendars) { calendar in
                        CustomGroupBox {
                            NavigationLink(value: AppRoute.features(.campusTool(.schoolCalendarList(.detail(calendar))))) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(calendar.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)

                                        Text(calendar.subtitle)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right").frame(width: 16)
                                }
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(asyncAction: viewModel.loadSchoolCalendars) {
                    if viewModel.isLoadingCalendars {
                        ProgressView().smallControlSizeOnMac()
                    } else {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        .task { await viewModel.loadSchoolCalendars() }
        .safeRefreshable { await viewModel.loadSchoolCalendars() }
        .errorToast($viewModel.errorToast)
        .navigationTitle("校历列表")
    }
}

#Preview {
    SchoolCalendarListView()
}
