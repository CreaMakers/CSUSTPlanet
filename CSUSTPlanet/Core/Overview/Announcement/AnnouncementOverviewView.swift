//
//  AnnouncementOverviewView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/29.
//

import CSUSTKit
import SwiftUI

struct AnnouncementOverviewView: View {
    @State private var viewModel = AnnouncementListViewModel()

    var body: some View {
        NavigationLink(value: AppRoute.overview(.announcementList(viewModel: viewModel))) {
            CustomGroupBox {
                cardContent
            }
        }
        .task { await viewModel.loadInitial(showError: false) }
        .buttonStyle(.plain)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("App公告")
                    .font(.title3)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)

                if viewModel.hasLoadedAnnouncements && viewModel.unreadAnnouncementsCount > 0 {
                    Text("\(viewModel.unreadAnnouncementsCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(.red, in: .capsule)
                }

                Spacer()

                if viewModel.hasLoadedAnnouncements && viewModel.unreadAnnouncementsCount > 0 {
                    Button {
                        viewModel.markAllAsRead()
                    } label: {
                        Text("全部已读")
                            .font(.subheadline)
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.borderless)
                }
            }

            HStack(spacing: 12) {
                if viewModel.unreadAnnouncementsCount > 0 {
                    Image(systemName: "megaphone.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                }

                Text(viewModel.unreadAnnouncementsCount > 0 ? "\(viewModel.unreadAnnouncementsCount) 条未读公告" : "无未读公告")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .redacted(reason: viewModel.hasLoadedAnnouncements ? [] : .placeholder)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        AnnouncementOverviewView()
            .padding()
    }
}
