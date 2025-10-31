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
                VStack {
                    Text("暂无宿舍信息")
                        .foregroundColor(.secondary)
                        .font(.headline)
                        .padding()
                    Button(action: { isShowingAddDormSheet = true }) {
                        Label("添加宿舍", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List(dorms) { dorm in
                    DormRowView(dorm: dorm)
                }
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

#Preview {
    NavigationStack {
        ElectricityQueryView()
    }
    .modelContainer((try? ModelContainer(for: Dorm.self, ElectricityRecord.self))!)
}
