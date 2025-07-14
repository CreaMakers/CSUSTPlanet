//
//  FeaturesView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import SwiftUI

struct FeaturesView: View {
    var body: some View {
        Form {
            Section(header: Text("生活服务")) {
                NavigationLink(destination: ElectricityQueryView()) {
                    Label("电量查询", systemImage: "bolt.fill")
                }
                NavigationLink(destination: CampusMapView()) {
                    Label("校园地图", systemImage: "map")
                }
                NavigationLink(destination: SchoolCalendarView()) {
                    Label("校历", systemImage: "calendar")
                }
            }

            Section(header: Text("考试查询")) {
                NavigationLink(destination: CETView()) {
                    Label("四六级", systemImage: "character.book.closed")
                }
                NavigationLink(destination: MandarinView()) {
                    Label("普通话", systemImage: "mic.fill")
                }
            }
        }
        .navigationTitle("功能")
    }
}

#Preview {
    NavigationStack {
        FeaturesView()
    }
}
