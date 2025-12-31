//
//  PhysicsExperimentLoginView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/11/3.
//

import SwiftUI

struct PhysicsExperimentLoginView: View {
    @Binding var isPresented: Bool

    @StateObject private var viewModel = PhysicsExperimentLoginViewModel()
    @EnvironmentObject var physicsExperimentManager: PhysicsExperimentManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))

                        Text("需要在校园网内才能登录物理实验教学管理平台，请确保您已连接到校园网。否则无法登录。")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 10)

                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.gray)
                        TextField("请输入用户名", text: $viewModel.username)
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
                    .padding(.horizontal)

                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.gray)

                        if viewModel.isPasswordVisible {
                            TextField("请输入密码", text: $viewModel.password)
                                .textFieldStyle(.plain)
                                .textContentType(.password)
                                .frame(height: 20)
                        } else {
                            SecureField("请输入密码", text: $viewModel.password)
                                .textFieldStyle(.plain)
                                .textContentType(.password)
                                .frame(height: 20)
                                .autocorrectionDisabled(true)
                        }

                        Button(action: {
                            viewModel.isPasswordVisible.toggle()
                        }) {
                            Image(systemName: viewModel.isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .padding(.horizontal)

                    Button(action: { viewModel.login($isPresented) }) {
                        HStack {
                            Text("登录")
                            if physicsExperimentManager.isLoggingIn {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                    }
                    .disabled(viewModel.isLoginDisabled)
                    .padding(.horizontal)
                    .padding(.top, 5)
                    .buttonStyle(.borderedProminent)

                    Spacer()
                }
            }
            .navigationTitle("登录大物实验")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { isPresented = false }) {
                        Text("关闭")
                    }
                }
            }
            .alert("错误", isPresented: $viewModel.isShowingError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .trackView("PhysicsExperimentLogin")
    }
}

#Preview {
    PhysicsExperimentLoginView(isPresented: .constant(true))
}
