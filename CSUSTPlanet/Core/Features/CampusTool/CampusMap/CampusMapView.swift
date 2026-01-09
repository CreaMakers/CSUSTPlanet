//
//  CampusMapView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import CSUSTKit
import MapKit
import SwiftUI
import Zoomable

struct CampusMapView: View {
    @StateObject private var viewModel = CampusMapViewModel()

    var url: URL {
        URL(string: "https://gis.csust.edu.cn/cmipsh5/#/")!
    }

    var body: some View {
        VStack(spacing: 0) {
            // Map View
            Map(position: $viewModel.mapPosition, selection: $viewModel.selectedBuilding) {
                ForEach(viewModel.filteredBuildings) { building in
                    MapPolygon(coordinates: viewModel.getPolygonCoordinates(for: building))
                        .foregroundStyle(viewModel.color(for: building.properties.category).opacity(viewModel.selectedBuilding == building ? 0.8 : 0.5))
                        .stroke(viewModel.selectedBuilding == building ? Color.primary : viewModel.color(for: building.properties.category), lineWidth: viewModel.selectedBuilding == building ? 2 : 1)
                        .tag(building)

                    Annotation(building.properties.name, coordinate: viewModel.getCenter(for: building)) {
                        EmptyView()
                    }
                    .tag(building)
                }
            }
            .frame(height: 350)

            // Category Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.availableCategories, id: \.self) { category in
                        Button(action: { withAnimation { viewModel.selectedCategory = category } }) {
                            Text(category ?? "全部")
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(viewModel.selectedCategory == category ? Color.accentColor : Color(.secondarySystemBackground))
                                .foregroundColor(viewModel.selectedCategory == category ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))

            // Building List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredBuildings) { building in
                        Button(action: { viewModel.selectBuilding(building) }) {
                            HStack(spacing: 16) {
                                // Icon
                                ZStack {
                                    Circle()
                                        .fill(viewModel.color(for: building.properties.category).opacity(0.1))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: viewModel.icon(for: building.properties.category))
                                        .font(.title2)
                                        .foregroundColor(viewModel.color(for: building.properties.category))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(building.properties.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Text(building.properties.category)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.selectedBuilding == building ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("校园地图")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.isOnlineMapShown) {
            SafariView(url: url).trackView("CampusMapOnline")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("校区", selection: $viewModel.selectedCampus) {
                        Text("金盆岭校区").tag(CampusCardHelper.Campus.jinpenling)
                        Text("云塘校区").tag(CampusCardHelper.Campus.yuntang)
                    }
                } label: {
                    Image(systemName: "building.2")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { viewModel.isOnlineMapShown = true }) {
                    Label("在线地图", systemImage: "globe")
                }
            }
        }
        .trackView("CampusMap")
    }
}

#Preview {
    NavigationStack {
        CampusMapView()
    }
}
