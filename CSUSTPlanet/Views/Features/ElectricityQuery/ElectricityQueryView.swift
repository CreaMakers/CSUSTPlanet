//
//  ElectricityQueryView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import SwiftData
import SwiftUI

struct ElectricityQueryView: View {
    @State var isShowingAddDormSheet: Bool = false
    @Environment(\.modelContext) private var modelContext

    @Query var dorms: [Dorm]

    var body: some View {
        ZStack {
            if dorms.isEmpty {
                VStack {
                    Text("暂无宿舍信息")
                        .foregroundColor(.secondary)
                        .font(.headline)
                        .padding()
                    Button(action: {
                        isShowingAddDormSheet.toggle()
                    }) {
                        Label("添加宿舍", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List(dorms) { dorm in
                    DormRowView(modelContext: modelContext, dorm: dorm)
                }
            }
        }
        .navigationTitle("电量查询")
        .navigationBarItems(
            trailing: Button(action: {
                isShowingAddDormSheet.toggle()
            }) {
                Label("添加宿舍", systemImage: "plus")
            }
        )
        .sheet(isPresented: $isShowingAddDormSheet) {
            AddDormitoryView(dorms: dorms, modelContext: modelContext, isShowingAddDormitorySheetBinding: $isShowingAddDormSheet)
        }
    }
}

#Preview {
    NavigationStack {
        ElectricityQueryView()
    }
    .modelContainer((try? ModelContainer(for: Dorm.self, ElectricityRecord.self))!)
}
