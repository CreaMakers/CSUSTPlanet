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
                        .foregroundStyle(color(for: building.properties.category).opacity(viewModel.selectedBuilding == building ? 0.8 : 0.5))
                        .stroke(viewModel.selectedBuilding == building ? Color.primary : color(for: building.properties.category), lineWidth: viewModel.selectedBuilding == building ? 2 : 1)
                        .tag(building)

                    Annotation(building.properties.name, coordinate: viewModel.getCenter(for: building)) {
                        EmptyView()
                    }
                    .tag(building)
                }
            }
            .frame(height: 300)

            // Category Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(BuildingCategory.allCases) { category in
                        Button(action: {
                            withAnimation {
                                viewModel.selectedCategory = category
                            }
                        }) {
                            Text(category.displayName)
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
                        Button(action: {
                            viewModel.selectBuilding(building)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(building.properties.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    HStack {
                                        Text(BuildingCategory(rawValue: building.properties.category)?.displayName ?? "其他")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(color(for: building.properties.category).opacity(0.1))
                                            .foregroundColor(color(for: building.properties.category))
                                            .cornerRadius(4)

                                        Spacer()
                                    }
                                }
                                Spacer()

                                if viewModel.selectedBuilding == building {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
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
            ToolbarItem(placement: .primaryAction) {
                Button(action: { viewModel.isOnlineMapShown = true }) {
                    Text("在线地图")
                }
            }
        }
        .trackView("CampusMap")
    }

    func color(for category: String) -> Color {
        switch category {
        case "teaching-building": return .orange
        case "library": return .blue
        case "dormitory": return .green
        case "canteen": return .red
        default: return .gray
        }
    }
}

#Preview {
    NavigationStack {
        CampusMapView()
    }
}
