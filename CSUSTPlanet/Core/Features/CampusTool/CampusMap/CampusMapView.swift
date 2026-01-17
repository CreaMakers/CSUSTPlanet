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
import UIKit

struct CampusMapView: View {
    @StateObject private var viewModel = CampusMapViewModel()

    @State private var stableSheetHeight: CGFloat = 0
    @State private var debounceTask: Task<Void, Never>? = nil
    @FocusState private var isSearchFocused: Bool

    private var campusTip = CampusTip()
    private var buildingInfoTip = BuildingInfoTip()
    private var onlineMapTip = OnlineMapTip()

    var url: URL {
        URL(string: "https://gis.csust.edu.cn/cmipsh5/#/")!
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
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
            .contentMargins(.bottom, stableSheetHeight, for: .scrollContent)
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
                MapPitchToggle()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button(action: viewModel.toggleBuildingsList) {
                Image(systemName: "building.columns")
                    .font(.title2)
                    .padding(12)
                    .background(.thickMaterial)
                    .clipShape(Circle())
            }
            // MARK: - 建筑物列表开关tip
            .popoverTip(buildingInfoTip) { action in
                if action.index == 0 {
                    buildingInfoTip.invalidate(reason: .actionPerformed)
                    OnlineMapTip.buildingListFinished = true
                }
            }
            .padding()
        }
        .background(
            WillDisappearHandler {
                viewModel.isBuildingsListShown = false
            }
        )
        .onChange(of: viewModel.isBuildingsListShown) { _, isShown in
            if !isShown {
                debounceTask?.cancel()
                stableSheetHeight = 0
            }
        }
        .sheet(isPresented: $viewModel.isBuildingsListShown) {
            sheetContent
                .presentationContentInteraction(.scrolls)
                .presentationBackgroundInteraction(.enabled)
                .presentationDetents([.fraction(0.3), .fraction(0.5), .fraction(0.7)], selection: $viewModel.settingsDetent)
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
                HStack(spacing: 20) {
                    Menu {
                        Picker("校区", selection: $viewModel.selectedCampus) {
                            Text("全部校区").tag(CampusCardHelper.Campus?.none)
                            Text("金盆岭校区").tag(Optional(CampusCardHelper.Campus.jinpenling))
                            Text("云塘校区").tag(Optional(CampusCardHelper.Campus.yuntang))
                        }
                    } label: {
                        Image(systemName: "building.2")
                    }
                    // MARK: - 校区选择tip
                    .popoverTip(campusTip) { action in
                        if action.index == 0 {
                            campusTip.invalidate(reason: .actionPerformed)
                            BuildingInfoTip.campusTipFinished = true
                        }
                    }

                    Button(action: viewModel.showOnlineMap) {
                        Image(systemName: "globe")
                    }
                    // MARK: - 在线地图tip
                    .popoverTip(onlineMapTip) { action in
                        if action.index == 0 {
                            onlineMapTip.invalidate(reason: .actionPerformed)
                        }
                    }
                }
            }
        }
        .task {
            viewModel.loadBuildings()
        }
        .trackView("CampusMap")
    }

    private var sheetContent: some View {
        VStack(spacing: 0) {
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("搜索建筑、地点...", text: $viewModel.searchText)
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
                .background(Color(.tertiarySystemFill))
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
                                .background(viewModel.selectedCategory == category ? Color.accentColor : Color(.secondarySystemBackground))
                                .foregroundColor(viewModel.selectedCategory == category ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

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

                                                Text(building.properties.campus + "校区 · " + building.properties.category)
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
        .onChange(of: isSearchFocused) { _, newValue in
            if newValue {
                withAnimation(.spring()) {
                    viewModel.settingsDetent = .fraction(0.7)
                }
            }
        }
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
}

extension CampusMapView {
    // MARK: - 1. 校区切换 Tip
    struct CampusTip: Tip {
        var title: Text { Text("切换校区") }
        var message: Text? { Text("点击此处可以切换金盆岭和云塘校区") }
        var image: Image? { Image(systemName: "building.2") }

        var actions: [Action] {
            [Tip.Action(id: "next", title: "下一步")]
        }

        var options: [TipOption] {
            [
                Tip.IgnoresDisplayFrequency(true)  // 必须加这个，否则很难连续弹
                // Tip.MaxDisplayCount(1) // 调试时注释掉
            ]
        }
    }

    // MARK: - 2. 列表开关 Tip
    struct BuildingInfoTip: Tip {
        var title: Text { Text("查看建筑物列表") }
        var message: Text? { Text("点击此处可以开启/关闭建筑物列表") }
        var image: Image? { Image(systemName: "list.bullet.indent") }

        var actions: [Action] {
            [Tip.Action(id: "next", title: "下一步")]
        }

        var rules: [Rule] {
            #Rule(Self.$campusTipFinished) { $0 == true }
        }

        var options: [TipOption] {
            [Tip.IgnoresDisplayFrequency(true)]
        }

        @Parameter
        static var campusTipFinished: Bool = false
    }

    // MARK: - 3. 在线地图 Tip
    struct OnlineMapTip: Tip {
        var title: Text { Text("在线地图") }
        var message: Text? { Text("点击此处打开在线地图") }

        var actions: [Action] {
            [Tip.Action(id: "close", title: "明白了")]
        }

        var rules: [Rule] {
            #Rule(Self.$buildingListFinished) { $0 == true }
        }

        var options: [TipOption] {
            [Tip.IgnoresDisplayFrequency(true)]
        }

        @Parameter
        static var buildingListFinished: Bool = false
    }
}

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

#Preview {
    NavigationStack {
        CampusMapView()
    }
}
