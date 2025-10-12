//
//  AddDormitoryView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import CSUSTKit
import SwiftUI

struct AddDormitoryView: View {
    @StateObject var viewModel = AddDormitoryViewModel()
    @Binding var isShowingAddDormSheet: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("选择校区")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Picker(selection: $viewModel.selectedCampus, label: Text("选择校区")) {
                            Text("金盆岭校区").tag(CampusCardHelper.Campus.jinpenling)
                            Text("云塘校区").tag(CampusCardHelper.Campus.yuntang)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: viewModel.selectedCampus, viewModel.handleCampusPickerChange)
                    }
                    .padding(.bottom, 20)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("选择宿舍楼")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        if viewModel.isBuildingsLoading {
                            ProgressView()
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        } else {
                            HStack {
                                Picker(selection: $viewModel.selectedBuildingID, label: Text("选择宿舍楼")) {
                                    if let buildings = viewModel.buildings[viewModel.selectedCampus] {
                                        ForEach(buildings, id: \.id) { building in
                                            Text(building.name).tag(building.id)
                                        }
                                    }
                                }
                                .fixedSize(horizontal: true, vertical: false)
                                .pickerStyle(.menu)
                                .disabled(viewModel.buildings[viewModel.selectedCampus]?.isEmpty ?? true)
                                .padding()

                                Spacer()

                                Button(action: viewModel.loadBuildings) {
                                    Label("刷新", systemImage: "arrow.clockwise")
                                        .padding()
                                }
                            }
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
                            TextField(viewModel.selectedCampus == .jinpenling ? "例如: 101" : "例如: A101或B203", text: $viewModel.room)
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
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

                    Button(action: { viewModel.handleAddDormitory($isShowingAddDormSheet) }) {
                        Text("确认添加")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                    }
                    .disabled(viewModel.selectedBuildingID.isEmpty || viewModel.room.isEmpty)
                    .padding(.top, 5)
                    .buttonStyle(.borderedProminent)

                    Spacer()
                }
                .padding(.horizontal, 25)
            }
            .task {
                viewModel.loadBuildings()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { isShowingAddDormSheet = false }) {
                        Text("取消")
                    }
                }
            }
            .navigationTitle("添加宿舍信息")
            .navigationBarTitleDisplayMode(.inline)
            .alert("错误", isPresented: $viewModel.isShowingError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}
