//
//  CampusMapView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import AlertToast
import CSUSTKit
import MapKit
import SwiftUI
import TipKit
import Zoomable

struct CampusMapView: View {
    @StateObject private var viewModel = CampusMapViewModel()

    private var campusTip = CampusTip()

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
                UserAnnotation()
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
                MapPitchToggle()
            }
            .frame(height: 320)

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
            ScrollViewReader { proxy in
                ScrollView {
                    if viewModel.filteredBuildings.isEmpty && !viewModel.searchText.isEmpty {
                        ContentUnavailableView.search(text: viewModel.searchText)
                            .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.filteredBuildings) { building in
                                HStack(spacing: 0) {
                                    Button(action: { viewModel.selectBuilding(building) }) {
                                        HStack(spacing: 12) {
                                            // Icon
                                            ZStack {
                                                Circle()
                                                    .fill(viewModel.color(for: building.properties.category).opacity(0.1))
                                                    .frame(width: 40, height: 40)
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
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    Button(action: { viewModel.openNavigation(for: building) }) {
                                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                            .font(.largeTitle)
                                            .symbolRenderingMode(.hierarchical)
                                            .foregroundColor(.accentColor)
                                            .frame(width: 50, height: 50)
                                    }
                                }
                                .padding(12)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(viewModel.selectedBuilding == building ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                                .padding(.horizontal)
                                .id(building.id)
                            }
                        }
                        .padding(.vertical)
                    }
                }
                .onChange(of: viewModel.selectedBuilding) { _, newValue in
                    if let building = newValue {
                        withAnimation {
                            proxy.scrollTo(building.id, anchor: .center)
                        }
                    }
                }
            }
        }
        .task {
            viewModel.loadBuildings()
        }
        .navigationTitle("校园地图")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, prompt: "搜索地址")
        .sheet(isPresented: $viewModel.isOnlineMapShown) {
            SafariView(url: url).trackView("CampusMapOnline")
        }
        .toast(isPresenting: $viewModel.isShowingError) {
            AlertToast(type: .error(.red), title: "错误", subTitle: viewModel.errorMessage)
        }
        .toast(isPresenting: $viewModel.isLoading) {
            AlertToast(type: .loading, title: "加载中", subTitle: "正在加载地图数据")
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
                .popoverTip(campusTip) { action in
                    if action.index == 0 {
                        campusTip.invalidate(reason: .actionPerformed)
                    }
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

extension CampusMapView {
    struct CampusTip: Tip {
        var title: Text { Text("切换校区") }
        var message: Text? { Text("点击此处可以切换金盆岭和云塘校区") }
        var image: Image? { Image(systemName: "building.2") }
        var actions: [Action] { [Action(title: "知道了")] }
        var options: [TipOption] { [Tip.MaxDisplayCount(1)] }
    }
}

#Preview {
    NavigationStack {
        CampusMapView()
    }
}
