//
//  ProfileDetailView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import SwiftUI

struct ProfileDetailView: View {
    @StateObject private var viewModel: ProfileViewModel

    init(authManager: AuthManager) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(
            ssoHelper: authManager.ssoHelper,
            eduHelper: authManager.eduHelper,
            moocHelper: authManager.moocHelper,
            ssoProfile: authManager.ssoProfile
        ))
    }

    var body: some View {
        Form {
            Section(header: Text("统一认证信息")) {
                if let ssoProfile = viewModel.ssoProfile {
                    RowView(title: "学生类型", value: ssoProfile.categoryName)
                    RowView(title: "账号", value: ssoProfile.userAccount)
                    RowView(title: "用户名", value: ssoProfile.userName)
                    RowView(title: "身份证", value: ssoProfile.certCode)
                    RowView(title: "手机号", value: ssoProfile.phone)
                    RowView(title: "邮箱", value: ssoProfile.email ?? "未设置")
                    RowView(title: "所属院系", value: ssoProfile.deptName)
                } else if viewModel.isSSOProfileLoading {
                    LoadingView()
                } else {
                    ErrorView(message: "统一认证信息加载失败").padding()
                }
            }

            Section(header: Text("教务信息")) {
                if let eduProfile = viewModel.eduProfile {
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
                } else if viewModel.isEduProfileLoading {
                    LoadingView()
                } else {
                    ErrorView(message: "教务信息加载失败").padding()
                }
            }

            Section(header: Text("网络课程中心信息")) {
                if let moocProfile = viewModel.moocProfile {
                    RowView(title: "姓名", value: moocProfile.name)
                    RowView(title: "上次登录时间", value: moocProfile.lastLoginTime)
                    RowView(title: "总在线时间", value: moocProfile.totalOnlineTime)
                    RowView(title: "登录次数", value: "\(moocProfile.loginCount)")
                } else if viewModel.isMoocProfileLoading {
                    LoadingView()
                } else {
                    ErrorView(message: "网络课程中心信息加载失败").padding()
                }
            }
        }
        .alert("错误", isPresented: $viewModel.isShowingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .navigationTitle("个人详情")
        .onAppear {
            viewModel.loadEduProfile()
            viewModel.loadMoocProfile()
        }
    }

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

    struct LoadingView: View {
        var body: some View {
            HStack {
                Spacer()
                ProgressView("加载中...")
                Spacer()
            }
        }
    }

    struct ErrorView: View {
        let message: String
        var body: some View {
            HStack {
                Spacer()
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .padding()
                    Text(message)
                }
                Spacer()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileDetailView(authManager: AuthManager.shared)
    }
}
