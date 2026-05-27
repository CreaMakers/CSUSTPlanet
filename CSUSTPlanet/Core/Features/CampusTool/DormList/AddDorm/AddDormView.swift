//
//  AddDormView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/21.
//

import CSUSTKit
import SwiftUI

struct AddDormView: View {
    @Environment(\.dismiss) private var dismiss
    var onConfirm: (_ room: CampusCardHelper.Room) -> Void
    @State var viewModel = AddDormViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("校区", selection: $viewModel.selectedCampus) {
                        ForEach(CampusCardHelper.Campus.allCases, id: \.self) { campus in
                            Text(campus.rawValue).tag(campus)
                        }
                    }

                    Picker("宿舍楼", selection: $viewModel.selectedBuilding) {
                        Text("请选择").tag(nil as CampusCardHelper.Building?)
                        ForEach(viewModel.buildings) { building in
                            Text(building.name).tag(building)
                        }
                    }
                    .disabled(viewModel.buildings.isEmpty)

                    Picker("宿舍", selection: $viewModel.selectedRoom) {
                        Text("请选择").tag(nil as CampusCardHelper.Room?)
                        ForEach(viewModel.rooms) { room in
                            Text(room.name).tag(room)
                        }
                    }
                    .disabled(viewModel.rooms.isEmpty)
                } header: {
                    Text("宿舍信息")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("添加宿舍")
            .inlineToolbarTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        guard let room = viewModel.selectedRoom else { return }
                        onConfirm(room)
                        dismiss()
                    }
                    .disabled(viewModel.selectedRoom == nil)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .task { await viewModel.loadInitial() }
            .errorToast($viewModel.errorToast)
        }
    }
}
