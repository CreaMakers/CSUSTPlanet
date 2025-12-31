//
//  CampusMapView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import CSUSTKit
import SwiftUI
import Zoomable

struct CampusMapView: View {
    @State private var selectedCampus: CampusCardHelper.Campus = .jinpenling
    @State private var isOnlineMapShown: Bool = false

    private var mapImageName: String {
        switch selectedCampus {
        case .yuntang: return "YuntangMap"
        case .jinpenling: return "JinpenlingMap"
        }
    }

    var url: URL {
        URL(string: "https://gis.csust.edu.cn/cmipsh5/#/")!
    }

    var body: some View {
        VStack(spacing: 10) {
            Picker("选择校区", selection: $selectedCampus) {
                Text("金盆岭校区").tag(CampusCardHelper.Campus.jinpenling)
                Text("云塘校区").tag(CampusCardHelper.Campus.yuntang)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top)

            GeometryReader { geo in
                Image(mapImageName)
                    .resizable()
                    .scaledToFit()
                    .zoomable(minZoomScale: 1, doubleTapZoomScale: 3, outOfBoundsColor: .clear)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .contentShape(Rectangle())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("校园地图")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isOnlineMapShown) {
            SafariView(url: url)
                .trackView("CampusMapOnline")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    isOnlineMapShown.toggle()
                }) {
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
