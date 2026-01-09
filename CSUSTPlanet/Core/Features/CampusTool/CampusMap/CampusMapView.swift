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
        Map(initialPosition: .region(MKCoordinateRegion(center: CampusMapViewModel.defaultLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))) {
            ForEach(viewModel.buildings) { building in
                MapPolygon(coordinates: building.polygonCoordinates)
                    .foregroundStyle(.orange.opacity(0.5))
                    .stroke(.orange, lineWidth: 1)

                Annotation(building.name, coordinate: building.center) {
                    EmptyView()
                }
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
}

#Preview {
    NavigationStack {
        CampusMapView()
    }
}
