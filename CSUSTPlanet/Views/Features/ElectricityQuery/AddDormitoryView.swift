//
//  AddDormitoryView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import CSUSTKit
import SwiftData
import SwiftUI

struct AddDormitoryView: View {
    let dorms: [Dorm]
    
    @Binding var isPresented: Bool
    
    @EnvironmentObject var electricityManager: ElectricityManager
    @Environment(\.modelContext) private var modelContext: ModelContext

    @State var selectedCampus: Campus = .jinpenling
    @State var selectedBuildingID: String = ""

    @State var room: String = ""

    @State var showErrorAlert: Bool = false
    @State var errorMessage: String = ""

    var body: some View {
        ScrollView {
            VStack {
                Text("添加宿舍信息")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("选择校区")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Picker(selection: $selectedCampus, label: Text("选择校区")) {
                        Text("金盆岭校区").tag(Campus.jinpenling)
                        Text("云塘校区").tag(Campus.yuntang)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedCampus) { _, newCampus in
                        if let firstBuilding = electricityManager.buildings[newCampus]?.first {
                            selectedBuildingID = firstBuilding.id
                        } else {
                            selectedBuildingID = ""
                        }
                    }
                }
                .padding(.bottom, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("选择宿舍楼")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if electricityManager.isBuildingsLoading {
                        ProgressView()
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    } else {
                        Picker(selection: $selectedBuildingID, label: Text("选择宿舍楼")) {
                            if let buildings = electricityManager.buildings[selectedCampus] {
                                ForEach(buildings, id: \.id) { building in
                                    Text(building.name).tag(building.id)
                                }
                            }
                        }
                        .pickerStyle(.menu)
                        .disabled(electricityManager.buildings[selectedCampus]?.isEmpty ?? true)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(.bottom, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("宿舍号")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "house.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 20)
                            .foregroundColor(.gray)
                        TextField(selectedCampus == .jinpenling ? "例如: 101" : "例如: A101或B203", text: $room)
                            .textFieldStyle(.plain)
                            .textContentType(.username)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .frame(height: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .padding(.top, 5)
                }
                .padding(.bottom, 30)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                        
                        Text("房间号填写提示：\n金盆岭校区不分A/B区，直接输入门牌号即可（如101）。\n云塘校区有A区、B区之分，需加前缀（如B306、A504）。")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.accent.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.bottom, 20)
                
                Spacer()
                
                Button(action: handleAddDormitory) {
                    Text("确认添加")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                }
                .disabled(selectedBuildingID.isEmpty || room.isEmpty)
                .padding(.top, 5)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 25)
            .padding(.top, 25)
            .task {
                do {
                    try await electricityManager.loadBuildings()
                    if let firstBuilding = electricityManager.buildings[selectedCampus]?.first {
                        selectedBuildingID = firstBuilding.id
                    }
                } catch {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                    
                    debugPrint(error)
                }
            }
            .alert("错误", isPresented: $showErrorAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    func handleAddDormitory() {
        let building = electricityManager.buildings[selectedCampus]?.first { $0.id == selectedBuildingID }
        guard let building = building else {
            errorMessage = "请选择有效的宿舍楼"
            showErrorAlert = true
            
            return
        }
        let dorm = Dorm(room: room, building: building)
        
        if dorms.contains(where: { $0.room == dorm.room && $0.buildingID == building.id && $0.buildingName == building.name }) {
            errorMessage = "该宿舍信息已存在"
            showErrorAlert = true
            
            return
        }

        modelContext.insert(dorm)
        isPresented = false
    }
}
