//
//  ProfileDetailView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import SwiftUI

struct RowView: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
        .contextMenu {
            Button(action: {
                UIPasteboard.general.string = value
            }) {
                Label("复制值", systemImage: "doc.on.doc")
            }
        }
    }
}

struct ProfileDetailView: View {
    @EnvironmentObject var userManager: UserManager

    @State private var showErrorAlert = false
    @State private var errorMessage: String = ""

    var body: some View {
        if !userManager.isLoggedIn {
            NotLoginView()
                .navigationTitle("个人详情")
        } else {
            Form {
                Section(header: Text("统一认证信息")) {
                    if let user = userManager.user {
                        RowView(title: "学生类型", value: user.categoryName)
                        RowView(title: "账号", value: user.userAccount)
                        RowView(title: "用户名", value: user.userName)
                        RowView(title: "身份证", value: user.certCode)
                        RowView(title: "手机号", value: user.phone)
                        RowView(title: "邮箱", value: user.email ?? "未设置")
                        RowView(title: "所属院系", value: user.deptName)
                    }
                }

                Section(header: Text("教务信息")) {
                    if userManager.isEduProfileLoading {
                        ProgressView("加载中...")
                    } else if let eduProfile = userManager.eduProfile {
                        RowView(title: "院系", value: eduProfile.department)
                        RowView(title: "专业", value: eduProfile.major)
                        RowView(title: "学制", value: eduProfile.educationSystem)
                        RowView(title: "班级", value: eduProfile.className)
                        RowView(title: "学号", value: eduProfile.studentID)
                        RowView(title: "姓名", value: eduProfile.name)
                        RowView(title: "性别", value: eduProfile.gender)
                        RowView(title: "姓名拼音", value: eduProfile.namePinyin)
                        RowView(title: "出生日期", value: eduProfile.birthDate)
                        RowView(title: "名族", value: eduProfile.ethnicity)
                        RowView(title: "学习层次", value: eduProfile.studyLevel)
                        RowView(title: "家庭现住址", value: eduProfile.homeAddress)
                        RowView(title: "家庭电话", value: eduProfile.homePhone)
                        RowView(title: "本人电话", value: eduProfile.personalPhone)
                        RowView(title: "入学日期", value: eduProfile.enrollmentDate)
                        RowView(title: "入学考号", value: eduProfile.entranceExamID)
                        RowView(title: "身份证编号", value: eduProfile.idCardNumber)
                    } else {
                        HStack {
                            Spacer()
                            VStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.largeTitle)
                                    .padding()
                                Text("教务信息加载失败")
                            }
                            Spacer()
                        }
                        .padding()
                    }
                }

                Section(header: Text("网络课程中心信息")) {
                    if userManager.isMoocProfileLoading {
                        ProgressView("加载中...")
                    } else if let moocProfile = userManager.moocProfile {
                        RowView(title: "姓名", value: moocProfile.name)
                        RowView(title: "上次登录时间", value: moocProfile.lastLoginTime)
                        RowView(title: "总在线时间", value: moocProfile.totalOnlineTime)
                        RowView(title: "登录次数", value: "\(moocProfile.loginCount)")
                    } else {
                        HStack {
                            Spacer()
                            VStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.largeTitle)
                                    .padding()
                                Text("网络课程中心信息加载失败")
                            }
                            Spacer()
                        }
                        .padding()
                    }
                }
            }
            .alert("错误", isPresented: $showErrorAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .navigationTitle("个人详情")
            .refreshable {
                do {
                    try await userManager.loadEduProfile()
                    try await userManager.loadMoocProfile()
                } catch {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true

                    debugPrint(error)
                }
            }
            .task {
                do {
                    try await userManager.loadEduProfile()
                    try await userManager.loadMoocProfile()
                } catch {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true

                    debugPrint(error)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileDetailView()
    }
    .environmentObject(UserManager())
}
