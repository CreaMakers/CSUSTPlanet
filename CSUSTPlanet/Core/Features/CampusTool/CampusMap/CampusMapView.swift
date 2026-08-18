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

#if os(iOS)
import UIKit
#endif

struct CampusMapView: View {
    @StateObject private var viewModel = CampusMapViewModel()
    @Environment(\.openURL) private var openURL

    @State private var stableSheetHeight: CGFloat = 0
    @State private var debounceTask: Task<Void, Never>? = nil
    @FocusState private var isSearchFocused: Bool
    @Environment(\.horizontalSizeClass) private var sizeClass

    var url: URL {
        URL(string: "https://gis.csust.edu.cn/cmipsh5/#/")!
    }

    private var usesInspectorForBuildingsList: Bool {
        #if os(macOS)
        true
        #elseif os(iOS)
        sizeClass != .compact
        #else
        false
        #endif
    }

    private var usesSheetForBuildingsList: Bool {
        !usesInspectorForBuildingsList
    }

    var body: some View {
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
        .applyIf(usesSheetForBuildingsList) { view in
            view.contentMargins(.bottom, stableSheetHeight, for: .scrollContent)
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
            MapPitchToggle()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(iOS)
        .hideTabBarOnCompact()
        .background(
            WillDisappearHandler {
                viewModel.isBuildingsListShown = false
            }
        )
        #endif
        .apply { view in
            if usesInspectorForBuildingsList {
                view
                    .inspector(isPresented: $viewModel.isBuildingsListShown) {
                        inspectorContent
                            .inspectorColumnWidth(min: 320, ideal: 360, max: 420)
                    }
            } else {
                view
                    .onChange(of: viewModel.isBuildingsListShown) { _, isShown in
                        if !isShown {
                            debounceTask?.cancel()
                            stableSheetHeight = 0
                        }
                    }
                    .sheet(isPresented: $viewModel.isBuildingsListShown) {
                        phoneSheetContent
                    }
            }
        }
        .navigationTitle("校园地图")
        .inlineToolbarTitle()
        #if os(iOS)
        .sheet(isPresented: $viewModel.isOnlineMapShown) {
            SafariView(url: url)
        }
        #endif
        .toast(isPresenting: $viewModel.isLoading) {
            AlertToast(type: .loading, title: "加载中", subTitle: "")
        }
        .errorToast($viewModel.errorToast)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Picker("校区", selection: $viewModel.selectedCampus) {
                        Text("全部校区").tag(CampusCardHelper.Campus?.none)
                        Text("金盆岭校区").tag(Optional(CampusCardHelper.Campus.jinpenling))
                        Text("云塘校区").tag(Optional(CampusCardHelper.Campus.yuntang))
                    }
                    .pickerStyle(.inline)
                } label: {
                    Image(systemName: "building.2")
                }

                #if os(iOS)
                Button(action: viewModel.showOnlineMap) {
                    Image(systemName: "globe")
                }
                #endif
            }

            ToolbarItem(placement: .navigation) {
                Button(action: viewModel.toggleBuildingsList) {
                    Image(systemName: "building.columns")
                }
            }
        }
        .task { await viewModel.loadInitial() }
    }

    private var phoneSheetContent: some View {
        buildingsListContent
            .presentationContentInteraction(.scrolls)
            .presentationBackgroundInteraction(.enabled)
            .presentationDetents([.fraction(0.3), .fraction(0.5), .fraction(0.7)], selection: $viewModel.settingsDetent)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            let h = proxy.size.height
                            if h > 0 { stableSheetHeight = h }
                        }
                        .onChange(of: proxy.size.height) { _, newHeight in
                            debounceTask?.cancel()
                            debounceTask = Task {
                                try? await Task.sleep(nanoseconds: 200_000_000)
                                if !Task.isCancelled && viewModel.isBuildingsListShown {
                                    stableSheetHeight = newHeight
                                }
                            }
                        }
                }
            }
    }

    private var inspectorContent: some View {
        buildingsListContent
    }

    private var buildingsListContent: some View {
        VStack(spacing: 0) {
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("搜索建筑、地点...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                        .overlay(alignment: .trailing) {
                            if !viewModel.searchText.isEmpty {
                                Button(action: { viewModel.searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                        .padding(.trailing, 4)
                                }
                            }
                        }
                }
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(24)

                if isSearchFocused {
                    Button("取消") {
                        isSearchFocused = false
                        viewModel.searchText = ""
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 8)
            .animation(.spring(), value: isSearchFocused)

            // Category Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.availableCategories, id: \.self) { category in
                        Button(action: { withAnimation { viewModel.selectedCategory = category } }) {
                            Text(category ?? "全部")
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(viewModel.selectedCategory == category ? Color.accentColor : Color.secondary.opacity(0.1))
                                .foregroundColor(viewModel.selectedCategory == category ? .white : .primary)
                                .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            // Building List
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    if viewModel.filteredBuildings.isEmpty && !viewModel.searchText.isEmpty {
                        ContentUnavailableView.search(text: viewModel.searchText)
                            .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.filteredBuildings) { building in
                                CustomGroupBox {
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

                                                    Text(building.properties.campus + "校区 · " + building.properties.category)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }

                                                Spacer()
                                            }
                                            .contentShape(.rect)
                                        }
                                        .buttonStyle(.plain)

                                        Button(action: { viewModel.openNavigation(for: building) }) {
                                            Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                                .font(.largeTitle)
                                                .symbolRenderingMode(.hierarchical)
                                                .foregroundColor(.accentColor)
                                                .frame(width: 50, height: 50)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
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
        .onChange(of: isSearchFocused) { _, newValue in
            if newValue {
                withAnimation(.spring()) {
                    viewModel.settingsDetent = .fraction(0.7)
                }
            }
        }
    }
}

#if os(iOS)
struct WillDisappearHandler: UIViewControllerRepresentable {
    let onWillDisappear: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        return WillDisappearViewController(onWillDisappear: onWillDisappear)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    class WillDisappearViewController: UIViewController {
        let onWillDisappear: () -> Void

        init(onWillDisappear: @escaping () -> Void) {
            self.onWillDisappear = onWillDisappear
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) { fatalError() }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            onWillDisappear()
        }
    }
}
#endif

#Preview {
    NavigationStack {
        CampusMapView()
    }
}
