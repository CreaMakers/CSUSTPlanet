//
//  ElectricityQueryView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import SwiftData
import SwiftUI

struct ElectricityQueryView: View {
    @State var isAddDormPopoverPresented: Bool = false

    @Query var dorms: [Dorm]

    @EnvironmentObject var electricityManager: ElectricityManager

    var body: some View {
        ZStack {
            if dorms.isEmpty {
                VStack {
                    Text("暂无宿舍信息")
                        .foregroundColor(.secondary)
                        .font(.headline)
                        .padding()
                    Button(action: {
                        isAddDormPopoverPresented.toggle()
                    }) {
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
        .navigationBarItems(
            trailing: Button(action: {
                isAddDormPopoverPresented.toggle()
            }) {
                Label("添加宿舍", systemImage: "plus")
            }
        )
        .popover(isPresented: $isAddDormPopoverPresented) {
            AddDormitoryView(dorms: dorms, isPresented: $isAddDormPopoverPresented)
        }
    }
}

#Preview {
    NavigationStack {
        ElectricityQueryView()
    }
    .environmentObject(ElectricityManager())
    .modelContainer((try? ModelContainer(for: Dorm.self, ElectricityRecord.self))!)
}
