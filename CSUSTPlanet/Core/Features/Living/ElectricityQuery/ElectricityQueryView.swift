//
//  ElectricityQueryView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import Inject
import SwiftData
import SwiftUI

struct ElectricityQueryView: View {
    @ObserveInjection var inject

    @State var isShowingAddDormSheet: Bool = false

    @Query var dorms: [Dorm]

    var body: some View {
        Group {
            if dorms.isEmpty {
                ContentUnavailableView(
                    "暂无宿舍",
                    systemImage: "house.slash",
                    description: Text("点击右上角添加您的宿舍信息")
                )
            } else {
                List {
                    ForEach(dorms) { dorm in
                        DormCardView(dorm: dorm)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .background(Color(uiColor: .systemGroupedBackground))
            }
        }
        .navigationTitle("电量查询")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { isShowingAddDormSheet = true }) {
                    Label("添加宿舍", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingAddDormSheet) {
            AddDormitoryView(isShowingAddDormSheet: $isShowingAddDormSheet)
        }
        .enableInjection()
    }
}
